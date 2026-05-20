# Hypershift Power Worker Nodes - Terraform Configuration

This Terraform configuration automates the creation and setup of Power VS worker nodes for Hypershift clusters on IBM Cloud. It replaces the bash scripts from the original Ansible playbook with infrastructure-as-code.

## Overview

This configuration:
- Creates Power VS instances for Hypershift worker nodes
- Configures PXE boot setup via bastion host
- Handles instance reboot and agent registration
- Supports multiple worker nodes in a single deployment

## Prerequisites

1. **IBM Cloud CLI** installed and configured
   ```bash
   curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
   ibmcloud plugin install power-iaas
   ```

2. **Terraform** (>= 1.0)
   ```bash
   # Download from https://www.terraform.io/downloads
   ```

3. **OpenShift CLI (oc)** installed and authenticated to your management cluster

4. **SSH Access** to the bastion host with private key

5. **IBM Cloud Resources**:
   - Power VS workspace
   - Private network configured
   - RHCOS image available
   - Bastion host with PXE boot scripts

## Configuration

### 1. Create terraform.tfvars

Copy the example file and fill in your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your specific values:

```hcl
ibmcloud_api_key        = "your-actual-api-key"
hypershift_cluster_name = "my-hypershift-cluster"
worker_count            = 2
bastion_ip              = "192.168.1.100"
```

### 2. Required Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `ibmcloud_api_key` | IBM Cloud API key | - (required) |
| `hypershift_cluster_name` | Name of your Hypershift cluster | - (required) |
| `bastion_ip` | IP address of bastion host | - (required) |
| `worker_count` | Number of worker nodes | 1 |
| `memory` | Memory per worker (GB) | 16 |
| `processors` | Processors per worker | 0.5 |
| `processor_type` | Processor type | "shared" |
| `system_type` | Power system type | "e980" |

### 3. Optional Variables

See `variables.tf` for all available configuration options including:
- Region and zone settings
- Network configuration
- Storage tier selection
- SSH key paths

## Usage

### Initialize Terraform

```bash
cd terraform/hypershift-workers
terraform init
```

### Plan the Deployment

Review what will be created:

```bash
terraform plan
```

### Apply the Configuration

Create the worker nodes:

```bash
terraform apply
```

Type `yes` when prompted to confirm.

### View Outputs

After successful deployment:

```bash
terraform output
```

This shows:
- Instance IDs
- IP addresses
- MAC addresses
- ISO download URL

### Destroy Resources

To remove all created resources:

```bash
terraform destroy
```

## Architecture

### Resource Flow

1. **Data Sources**: Fetch Power VS workspace, network, and RHCOS image details
2. **ISO URL Retrieval**: Query OpenShift for the infraenv ISO download URL
3. **Instance Creation**: Create Power VS instances with specified configuration
4. **Wait Period**: Allow instances to fully provision (5 minutes)
5. **PXE Boot Setup**: SSH to bastion and configure PXE boot for each instance
6. **Instance Reboot**: Soft reboot instances to boot from PXE
7. **Agent Registration**: Wait for OpenShift agents to register (optional)

### Network Architecture

```
Management Cluster (OpenShift)
    ↓ (ISO URL)
Terraform Controller
    ↓ (API calls)
IBM Cloud Power VS
    ├── Worker Instance 1 (Power)
    ├── Worker Instance 2 (Power)
    └── ...
    ↓ (PXE Boot)
Bastion Host
    └── PXE Boot Scripts
```

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   ```bash
   # Verify IBM Cloud login
   ibmcloud login --apikey YOUR_API_KEY
   ibmcloud target -r jp-tok -g ipi-resource-group
   ```

2. **OpenShift Connection Issues**
   ```bash
   # Verify oc is authenticated
   oc whoami
   oc get infraenv -n clusters-YOUR_CLUSTER_NAME
   ```

3. **SSH Connection to Bastion**
   ```bash
   # Test SSH access
   ssh -i /root/id_rsa root@BASTION_IP "echo 'Connection successful'"
   ```

4. **Instance Creation Timeout**
   - Check Power VS workspace capacity
   - Verify network configuration
   - Review IBM Cloud status page

### Debug Mode

Enable Terraform debug logging:

```bash
export TF_LOG=DEBUG
terraform apply
```

### State Management

View current state:
```bash
terraform state list
terraform state show ibm_pi_instance.power_worker[0]
```

## Agent Approval (Optional)

The configuration includes commented-out code for automatic agent approval. To enable:

1. Uncomment the `null_resource.approve_agent` block in `main.tf`
2. Adjust the logic based on your cluster requirements
3. Re-apply the configuration

## Comparison with Original Bash Script

| Feature | Bash Script | Terraform |
|---------|-------------|-----------|
| Idempotency | No | Yes |
| State Management | Manual | Automatic |
| Parallel Execution | Sequential | Parallel (where possible) |
| Error Handling | Basic | Comprehensive |
| Rollback | Manual | Automatic |
| Documentation | Comments | Self-documenting |

## Security Considerations

1. **API Key Storage**: Never commit `terraform.tfvars` with real credentials
2. **State File**: Contains sensitive data - store securely (use remote backend)
3. **SSH Keys**: Protect private keys with appropriate permissions
4. **Network Access**: Ensure bastion host is properly secured

## Remote State Backend (Recommended)

For production use, configure remote state:

```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "hypershift-workers/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Contributing

When modifying this configuration:
1. Test changes in a non-production environment
2. Update this README with any new variables or features
3. Follow Terraform best practices
4. Document any breaking changes

## References

- [IBM Cloud Terraform Provider](https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs)
- [Power VS Documentation](https://cloud.ibm.com/docs/power-iaas)
- [Hypershift Documentation](https://hypershift-docs.netlify.app/)
- [Original Ansible Playbook](../../playbooks/roles/hypershift-agent/)

## License

See [LICENSE.txt](../../LICENCE.txt) in the repository root.

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review IBM Cloud Power VS documentation
3. Open an issue in the repository
