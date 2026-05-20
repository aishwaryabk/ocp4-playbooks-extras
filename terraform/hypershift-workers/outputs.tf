output "power_worker_instances" {
  description = "Details of all Power VS worker instances"
  value = {
    for idx, instance in ibm_pi_instance.power_worker : idx => {
      instance_id   = instance.instance_id
      instance_name = instance.pi_instance_name
      ip_address    = instance.pi_network[0].ip_address
      mac_address   = instance.pi_network[0].mac_address
      status        = instance.status
    }
  }
}

output "worker_instance_ids" {
  description = "List of Power VS worker instance IDs"
  value       = [for instance in ibm_pi_instance.power_worker : instance.instance_id]
}

output "worker_ip_addresses" {
  description = "List of IP addresses for Power VS worker instances"
  value       = [for instance in ibm_pi_instance.power_worker : instance.pi_network[0].ip_address]
}

output "worker_mac_addresses" {
  description = "List of MAC addresses for Power VS worker instances"
  value       = [for instance in ibm_pi_instance.power_worker : instance.pi_network[0].mac_address]
}

output "iso_download_url" {
  description = "ISO download URL from the infraenv"
  value       = data.external.iso_url.result.iso_url
  sensitive   = true
}

output "hypershift_cluster_name" {
  description = "Name of the Hypershift cluster"
  value       = var.hypershift_cluster_name
}

output "worker_count" {
  description = "Number of worker nodes created"
  value       = var.worker_count
}

output "bastion_ip" {
  description = "Bastion host IP address used for PXE boot setup"
  value       = var.bastion_ip
}
