variable "ibmcloud_api_key" {
  description = "IBM Cloud API key for authentication"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "IBM Cloud region (e.g., jp-tok)"
  type        = string
  default     = "jp-tok"
}

variable "zone" {
  description = "IBM Cloud zone"
  type        = string
  default     = "tok04"
}

variable "resource_group" {
  description = "IBM Cloud resource group name"
  type        = string
  default     = "ipi-resource-group"
}

variable "power_instance_id" {
  description = "Power VS workspace CRN or GUID"
  type        = string
  default     = "crn:v1:bluemix:public:power-iaas:tok04:a/bf9f1f230466481b95a99f18739fede9:d3814f7d-bbf0-4c56-aaa2-e0d2ddec6e38::"
}

variable "network_name" {
  description = "Name of the Power VS network to attach instances to"
  type        = string
  default     = "ocp-private-net"
}

variable "rhcos_image_name" {
  description = "Name of the RHCOS image in Power VS"
  type        = string
  default     = "rhcos-417--tier1"
}

variable "hypershift_cluster_name" {
  description = "Name of the Hypershift cluster"
  type        = string
}

variable "worker_count" {
  description = "Number of Power worker nodes to create"
  type        = number
  default     = 1
  validation {
    condition     = var.worker_count > 0 && var.worker_count <= 10
    error_message = "Worker count must be between 1 and 10."
  }
}

variable "memory" {
  description = "Memory allocation for each worker node in GB"
  type        = number
  default     = 16
}

variable "processors" {
  description = "Number of processors for each worker node"
  type        = number
  default     = 0.5
}

variable "processor_type" {
  description = "Processor type (shared, dedicated, capped)"
  type        = string
  default     = "shared"
  validation {
    condition     = contains(["shared", "dedicated", "capped"], var.processor_type)
    error_message = "Processor type must be one of: shared, dedicated, capped."
  }
}

variable "system_type" {
  description = "System type for Power VS instance (e.g., e980, s922)"
  type        = string
  default     = "e980"
}

variable "storage_tier" {
  description = "Storage tier for the instance (tier1, tier3)"
  type        = string
  default     = "tier1"
  validation {
    condition     = contains(["tier1", "tier3"], var.storage_tier)
    error_message = "Storage tier must be either tier1 or tier3."
  }
}

variable "bastion_ip" {
  description = "IP address of the bastion host for PXE boot setup"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key for bastion host access"
  type        = string
  default     = "/root/id_rsa"
}

variable "dns_instance_name" {
  description = "IBM Cloud Internet Services (CIS) instance name for DNS"
  type        = string
  default     = "rdr-ipi-validation-dns"
}
