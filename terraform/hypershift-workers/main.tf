terraform {
  required_version = ">= 1.0"
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 1.60"
    }
  }
}

provider "ibm" {
  ibmcloud_api_key = var.ibmcloud_api_key
  region           = var.region
  zone             = var.zone
}

# Data source to get the Power VS workspace
data "ibm_pi_workspace" "workspace" {
  pi_cloud_instance_id = var.power_instance_id
}

# Data source to get the network
data "ibm_pi_network" "private_network" {
  pi_cloud_instance_id = var.power_instance_id
  pi_network_name      = var.network_name
}

# Data source to get the RHCOS image
data "ibm_pi_image" "rhcos" {
  pi_cloud_instance_id = var.power_instance_id
  pi_image_name        = var.rhcos_image_name
}

# Get ISO download URL from OpenShift cluster
data "external" "iso_url" {
  program = ["bash", "-c", <<-EOT
    oc get infraenv ${var.hypershift_cluster_name}-ppc -n clusters-${var.hypershift_cluster_name} -o json | jq -r '{iso_url: .status.isoDownloadURL}'
  EOT
  ]
}

# Create Power VS instances for worker nodes
resource "ibm_pi_instance" "power_worker" {
  count = var.worker_count

  pi_cloud_instance_id = var.power_instance_id
  pi_instance_name     = "${var.hypershift_cluster_name}-power-worker-${count.index}"
  pi_image_id          = data.ibm_pi_image.rhcos.id
  pi_memory            = var.memory
  pi_processors        = var.processors
  pi_proc_type         = var.processor_type
  pi_sys_type          = var.system_type
  pi_storage_type      = var.storage_tier

  pi_network {
    network_id = data.ibm_pi_network.private_network.id
  }

  # Wait for instance to be created
  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

# Wait for instances to be fully provisioned
resource "time_sleep" "wait_for_instance" {
  count = var.worker_count

  depends_on = [ibm_pi_instance.power_worker]

  create_duration = "300s"
}

# Setup PXE boot on bastion host
resource "null_resource" "setup_pxe_boot" {
  count = var.worker_count

  depends_on = [time_sleep.wait_for_instance]

  connection {
    type        = "ssh"
    host        = var.bastion_ip
    user        = "root"
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "echo '${data.external.iso_url.result.iso_url}' > /tmp/${var.hypershift_cluster_name}-iso-download-link",
      "mkdir -p /tmp/shared",
      "echo '${ibm_pi_instance.power_worker[count.index].pi_network[0].ip_address}' > /tmp/shared/ippoweraddr",
      "echo 'Setting up PXE boot for ${ibm_pi_instance.power_worker[count.index].pi_instance_name}'",
      "./agent-ci/scripts/setup-pxe-boot.sh ${var.hypershift_cluster_name} ${var.worker_count} ${ibm_pi_instance.power_worker[count.index].pi_instance_name},${ibm_pi_instance.power_worker[count.index].pi_network[0].mac_address},${ibm_pi_instance.power_worker[count.index].pi_network[0].ip_address}",
      "sleep 240"
    ]
  }
}

# Reboot Power VS instances
resource "null_resource" "reboot_instance" {
  count = var.worker_count

  depends_on = [null_resource.setup_pxe_boot]

  provisioner "local-exec" {
    command = <<-EOT
      ibmcloud login --apikey ${var.ibmcloud_api_key}
      ibmcloud target -r ${var.region} -g ${var.resource_group}
      ibmcloud pi ws tg ${var.power_instance_id}
      ibmcloud pi ins act ${ibm_pi_instance.power_worker[count.index].instance_id} --operation soft-reboot
    EOT
  }
}

# Wait after reboot
resource "time_sleep" "wait_after_reboot" {
  count = var.worker_count

  depends_on = [null_resource.reboot_instance]

  create_duration = "600s"
}

# Optional: Agent approval (commented out as in original script)
# Uncomment and modify if you want to automate agent approval
/*
resource "null_resource" "approve_agent" {
  count = var.worker_count

  depends_on = [time_sleep.wait_after_reboot]

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for agent to be generated
      while true; do
        agent=$(oc get agents -n "clusters-${var.hypershift_cluster_name}" --no-headers 2>/dev/null | awk '{print $1}')
        if [ -n "$agent" ]; then
          echo "Agent detected: $agent"
          if oc get agent -A --no-headers | awk '{if ($${var.worker_count}=="false" || $4=="false") exit 0} END{exit 1}'; then
            oc -n "clusters-${var.hypershift_cluster_name}" patch agent $agent -p '{"spec":{"approved":true,"hostname":"worker-${count.index}.${var.hypershift_cluster_name}.qe-ppc64le.cis.ibm.net"}}' --type merge
            oc -n clusters scale nodepool ${var.hypershift_cluster_name}-ppc --replicas $((${count.index}+1))
          else
            echo "Agents are already approved"
          fi
          break
        fi
        sleep 5
      done

      # Wait for agent to be in Done state
      while true; do
        if oc get agent -A --no-headers | awk '{if ($5=="Done") exit 0} END{exit 1}'; then
          echo "Agent is Done"
          break
        else
          echo "Agent not Done yet"
        fi
        sleep 10
      done
    EOT
  }
}
*/
