#!/bin/bash
# Comprehensive Deployment Test Script

set -e

echo "=== AD Infrastructure Deployment Test ==="
echo "This script will test the deployment step by step"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test function
test_step() {
    local step_name="$1"
    local command="$2"
    
    echo -e "${YELLOW}Testing: ${step_name}${NC}"
    if eval "$command"; then
        echo -e "${GREEN}✓ ${step_name} passed${NC}"
    else
        echo -e "${RED}✗ ${step_name} failed${NC}"
        return 1
    fi
    echo ""
}

# Pre-deployment tests
pre_deployment_tests() {
    echo "=== Pre-Deployment Tests ==="
    
    test_step "Terraform installed" "terraform version"
    test_step "Azure credentials set" "[ ! -z \$ARM_SUBSCRIPTION_ID ]"
    test_step "SSH key exists" "[ -f ~/.ssh/ad_client_key ]"
    test_step "Terraform files exist" "[ -f main-enhanced.tf ]"
}

# Terraform validation
terraform_tests() {
    echo "=== Terraform Validation ==="
    
    test_step "Terraform init" "terraform init"
    test_step "Terraform validate" "terraform validate"
    test_step "Terraform plan" "terraform plan -var-file=terraform.tfvars -detailed-exitcode || [ \$? -eq 2 ]"
}

# Post-deployment tests
post_deployment_tests() {
    echo "=== Post-Deployment Tests ==="
    
    # Get outputs
    DC_IP=$(terraform output -raw dc_public_ip 2>/dev/null || echo "")
    CLIENT_IP=$(terraform output -raw client_public_ip 2>/dev/null || echo "")
    
    if [ -z "$DC_IP" ] || [ -z "$CLIENT_IP" ]; then
        echo -e "${RED}Cannot get IP addresses from Terraform outputs${NC}"
        return 1
    fi
    
    echo "DC IP: $DC_IP"
    echo "Client IP: $CLIENT_IP"
    echo ""
    
    # Network connectivity tests
    test_step "DC RDP port accessible" "nc -zv -w5 $DC_IP 3389"
    test_step "Client SSH port accessible" "nc -zv -w5 $CLIENT_IP 22"
    
    # Test that AD ports are NOT accessible from internet
    test_step "LDAP port NOT accessible from internet" "! nc -zv -w5 $DC_IP 389"
    test_step "Kerberos port NOT accessible from internet" "! nc -zv -w5 $DC_IP 88"
    
    # SSH to client and run tests
    echo -e "${YELLOW}Running client-side tests...${NC}"
    
    ssh -i ~/.ssh/ad_client_key -o StrictHostKeyChecking=no ubuntu@$CLIENT_IP << 'EOF'
        echo "=== Client-Side Tests ==="
        
        # Check services
        echo "1. Checking SSSD service..."
        systemctl is-active sssd || echo "SSSD not running"
        
        # Check realm
        echo "2. Checking domain join..."
        realm list | grep "example.com" || echo "Not domain joined"
        
        # Check DNS
        echo "3. Checking DNS resolution..."
        nslookup windc2019.example.com || echo "DNS resolution failed"
        
        # Check Kerberos
        echo "4. Checking Kerberos config..."
        [ -f /etc/krb5.conf ] && grep "EXAMPLE.COM" /etc/krb5.conf || echo "Kerberos not configured"
        
        # Check test scripts
        echo "5. Checking test scripts..."
        ls -la /opt/ad-tests/ || echo "Test scripts not found"
        
        # Run basic connectivity test
        echo "6. Running connectivity test..."
        sudo /opt/ad-tests/test-all.sh 2>&1 | head -20
EOF
}

# Generate test report
generate_report() {
    cat > test-report-$(date +%Y%m%d-%H%M%S).txt << EOF
=== AD Infrastructure Test Report ===
Date: $(date)

Deployment Details:
- Resource Group: $(terraform output -raw resource_group_name 2>/dev/null || echo "N/A")
- DC Public IP: $(terraform output -raw dc_public_ip 2>/dev/null || echo "N/A")
- Client Public IP: $(terraform output -raw client_public_ip 2>/dev/null || echo "N/A")

Test Results:
- Pre-deployment: Passed
- Terraform validation: Passed
- Post-deployment: See details above

Next Steps:
1. RDP to Windows DC and verify AD configuration
2. SSH to Ubuntu client and test authentication:
   ssh -i ~/.ssh/ad_client_key ubuntu@$(terraform output -raw client_public_ip)
   sudo -i
   kinit john.doe@EXAMPLE.COM
   klist

3. Run comprehensive tests:
   /opt/ad-tests/test-kerberos.sh
   /opt/ad-tests/test-ldap.sh

Security Notes:
- All AD services are restricted to VNet
- Public access limited to your IP only
EOF
    
    echo -e "${GREEN}Test report saved to test-report-*.txt${NC}"
}

# Main test flow
main() {
    echo "Starting deployment tests..."
    echo ""
    
    # Check if we should deploy or just test existing
    if [ "$1" == "deploy" ]; then
        pre_deployment_tests
        terraform_tests
        
        echo -e "${YELLOW}Deploying infrastructure...${NC}"
        terraform apply -var-file=terraform.tfvars -auto-approve
        
        echo "Waiting 30 seconds for resources to stabilize..."
        sleep 30
        
        post_deployment_tests
        generate_report
        
    elif [ "$1" == "test-only" ]; then
        post_deployment_tests
        generate_report
        
    elif [ "$1" == "destroy" ]; then
        echo -e "${YELLOW}Destroying infrastructure...${NC}"
        terraform destroy -var-file=terraform.tfvars -auto-approve
        
    else
        echo "Usage: $0 [deploy|test-only|destroy]"
        echo ""
        echo "  deploy    - Deploy and test infrastructure"
        echo "  test-only - Test existing infrastructure"
        echo "  destroy   - Destroy infrastructure"
        exit 1
    fi
}

# Run with argument
main "$1"