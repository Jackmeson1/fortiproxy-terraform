#!/bin/bash
# Secure Deployment Script for AD Infrastructure

set -e

echo "=== Azure AD Infrastructure Deployment ==="
echo ""

# Check if environment variables are set
check_env_vars() {
    local missing=0
    
    if [ -z "$ARM_SUBSCRIPTION_ID" ]; then
        echo "❌ ARM_SUBSCRIPTION_ID is not set"
        missing=1
    fi
    
    if [ -z "$ARM_CLIENT_ID" ]; then
        echo "❌ ARM_CLIENT_ID is not set"
        missing=1
    fi
    
    if [ -z "$ARM_CLIENT_SECRET" ]; then
        echo "❌ ARM_CLIENT_SECRET is not set"
        missing=1
    fi
    
    if [ -z "$ARM_TENANT_ID" ]; then
        echo "❌ ARM_TENANT_ID is not set"
        missing=1
    fi
    
    if [ $missing -eq 1 ]; then
        echo ""
        echo "Please set Azure credentials using one of these methods:"
        echo "1. Source the setup-env.sh script: source ./setup-env.sh"
        echo "2. Export variables manually"
        echo "3. Use a .env file with direnv"
        exit 1
    fi
    
    echo "✅ All Azure environment variables are set"
}

# Generate SSH key if not exists
generate_ssh_key() {
    if [ ! -f ~/.ssh/ad_client_key ]; then
        echo "Generating SSH key pair for Ubuntu client..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/ad_client_key -N "" -q
        echo "✅ SSH key generated: ~/.ssh/ad_client_key"
    else
        echo "✅ SSH key already exists: ~/.ssh/ad_client_key"
    fi
}

# Get current public IP
get_public_ip() {
    echo "Detecting your public IP address..."
    PUBLIC_IP=$(curl -s ifconfig.me)
    echo "✅ Your public IP: $PUBLIC_IP"
    export TF_VAR_admin_source_ip="${PUBLIC_IP}/32"
}

# Create terraform.tfvars
create_tfvars() {
    if [ -f terraform.tfvars ]; then
        echo "⚠️  terraform.tfvars already exists. Backing up..."
        cp terraform.tfvars terraform.tfvars.backup-$(date +%Y%m%d-%H%M%S)
    fi
    
    SSH_KEY=$(cat ~/.ssh/ad_client_key.pub)
    
    cat > terraform.tfvars << EOF
# Auto-generated Terraform variables
# Generated on: $(date)

# Azure credentials are set via environment variables

# Resource Configuration
location            = "eastus"
resource_group_name = "ADTestRG-$(date +%Y%m%d)"

# Windows DC Configuration
admin_username = "azureuser"
admin_password = "P@ssw0rd-$(openssl rand -hex 4)!"  # Random secure password
domain_name    = "example.com"
vm_size        = "Standard_B2ms"

# Security Configuration
admin_source_ip = "${PUBLIC_IP}/32"

# Ubuntu Client Configuration
client_vm_size        = "Standard_B2s"
client_admin_username = "ubuntu"
client_ssh_public_key = "${SSH_KEY}"
EOF
    
    echo "✅ terraform.tfvars created with secure configuration"
    echo "⚠️  Admin password has been randomly generated - check terraform.tfvars"
}

# Initialize Terraform
init_terraform() {
    echo ""
    echo "Initializing Terraform..."
    terraform init
    echo "✅ Terraform initialized"
}

# Plan deployment
plan_deployment() {
    echo ""
    echo "Planning deployment..."
    
    # Use enhanced configuration
    if [ -f main-enhanced.tf ]; then
        echo "Using enhanced configuration..."
        terraform plan \
            -var-file=terraform.tfvars \
            -out=tfplan \
            main-enhanced.tf
    else
        terraform plan \
            -var-file=terraform.tfvars \
            -out=tfplan
    fi
    
    echo "✅ Deployment plan created"
}

# Apply deployment
apply_deployment() {
    echo ""
    read -p "Do you want to apply this deployment? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo "Applying deployment..."
        terraform apply tfplan
        echo "✅ Deployment completed!"
        
        # Show outputs
        echo ""
        echo "=== Deployment Outputs ==="
        terraform output -json > deployment-outputs.json
        terraform output
        
        # Save connection info
        save_connection_info
    else
        echo "Deployment cancelled"
        exit 0
    fi
}

# Save connection information
save_connection_info() {
    DC_IP=$(terraform output -raw dc_public_ip 2>/dev/null || echo "pending")
    CLIENT_IP=$(terraform output -raw client_public_ip 2>/dev/null || echo "pending")
    
    cat > connection-info.txt << EOF
=== AD Infrastructure Connection Information ===
Generated: $(date)

Windows Domain Controller:
- Public IP: ${DC_IP}
- RDP: mstsc /v:${DC_IP}
- Username: azureuser
- Password: Check terraform.tfvars

Ubuntu Client:
- Public IP: ${CLIENT_IP}
- SSH: ssh -i ~/.ssh/ad_client_key ubuntu@${CLIENT_IP}

Domain: example.com
Realm: EXAMPLE.COM

Test Commands:
1. SSH to Ubuntu client
2. Run: sudo /opt/ad-tests/test-all.sh
3. Test auth: kinit john.doe@EXAMPLE.COM

Security Note: All AD services are restricted to VNet only.
Only RDP and SSH are accessible from ${PUBLIC_IP}/32
EOF
    
    echo ""
    echo "✅ Connection information saved to connection-info.txt"
}

# Main execution
main() {
    echo "Starting secure AD infrastructure deployment..."
    echo ""
    
    check_env_vars
    generate_ssh_key
    get_public_ip
    create_tfvars
    init_terraform
    plan_deployment
    apply_deployment
    
    echo ""
    echo "=== Deployment Complete ==="
    echo "Check connection-info.txt for access details"
    echo ""
    echo "⚠️  IMPORTANT SECURITY NOTES:"
    echo "1. Change the admin password after first login"
    echo "2. Review and update NSG rules as needed"
    echo "3. Consider using Azure Bastion for production"
    echo "4. Enable Azure AD audit logging"
}

# Run main function
main