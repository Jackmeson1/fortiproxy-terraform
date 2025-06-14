#!/bin/bash
# Azure Environment Setup Script
# This script sets up Azure credentials as environment variables

echo "Setting up Azure environment variables..."

# Azure Service Principal Credentials
export ARM_SUBSCRIPTION_ID="your-subscription-id"
export ARM_CLIENT_ID="your-client-id"
export ARM_CLIENT_SECRET="your-client-secret"
export ARM_TENANT_ID="your-tenant-id"

# Verify environment variables are set
if [ -z "$ARM_SUBSCRIPTION_ID" ] || [ -z "$ARM_CLIENT_ID" ] || [ -z "$ARM_CLIENT_SECRET" ] || [ -z "$ARM_TENANT_ID" ]; then
    echo "Error: Please update this script with your actual Azure credentials"
    return 1
fi

echo "Azure environment variables set successfully!"
echo "You can now run Terraform commands."

# Optional: Set additional Terraform variables
export TF_VAR_admin_source_ip="$(curl -s ifconfig.me)/32"  # Auto-detect your public IP
echo "Admin source IP set to: $TF_VAR_admin_source_ip"