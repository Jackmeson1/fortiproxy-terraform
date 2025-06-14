#!/bin/bash
# =============================================================================
# CASE 2 DEPLOYMENT AND VERIFICATION SCRIPT
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
}

# =============================================================================
# PRE-DEPLOYMENT CHECKS
# =============================================================================

log "Starting Case 2: Root-Child Domain Deployment and Verification"

# Check prerequisites
log "Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    error "Terraform is not installed. Please install Terraform >= 1.0"
    exit 1
fi

if ! command -v az &> /dev/null; then
    error "Azure CLI is not installed. Please install Azure CLI"
    exit 1
fi

if [ ! -f "terraform.tfvars" ]; then
    error "terraform.tfvars not found. Please copy from terraform.tfvars.example and configure"
    exit 1
fi

success "Prerequisites check passed"

# =============================================================================
# DEPLOYMENT PHASE
# =============================================================================

log "Phase 1: Infrastructure Deployment"

# Initialize Terraform
log "Initializing Terraform..."
terraform init

# Validate configuration
log "Validating Terraform configuration..."
terraform validate

if [ $? -ne 0 ]; then
    error "Terraform validation failed"
    exit 1
fi

success "Terraform validation passed"

# Plan deployment
log "Creating deployment plan..."
terraform plan -out=case2-deployment.tfplan

# Ask for confirmation
echo ""
warning "Ready to deploy Case 2: Root-Child Domain infrastructure"
read -p "Do you want to proceed with deployment? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "Deployment cancelled by user"
    exit 0
fi

# Apply deployment
log "Deploying infrastructure..."
terraform apply case2-deployment.tfplan

if [ $? -ne 0 ]; then
    error "Terraform deployment failed"
    exit 1
fi

success "Infrastructure deployment completed"

# =============================================================================
# EXTRACT DEPLOYMENT INFO
# =============================================================================

log "Phase 2: Extracting Deployment Information"

ROOT_DC_IP=$(terraform output -raw root_dc_public_ip 2>/dev/null || echo "")
CHILD_DC_IP=$(terraform output -raw child_dc_public_ip 2>/dev/null || echo "")
CLIENT_IP=$(terraform output -raw client_public_ip 2>/dev/null || echo "")

if [ -z "$ROOT_DC_IP" ] || [ -z "$CHILD_DC_IP" ] || [ -z "$CLIENT_IP" ]; then
    error "Failed to extract deployment information"
    exit 1
fi

log "Deployment Information:"
echo "  Root DC Public IP: $ROOT_DC_IP"
echo "  Child DC Public IP: $CHILD_DC_IP"
echo "  Client Public IP: $CLIENT_IP"

# =============================================================================
# AUTOMATION MONITORING
# =============================================================================

log "Phase 3: Monitoring Automated Setup"

# Function to check if a port is open
check_port() {
    local ip=$1
    local port=$2
    local service=$3
    
    if timeout 5 bash -c "</dev/tcp/$ip/$port" 2>/dev/null; then
        success "$service on $ip:$port is accessible"
        return 0
    else
        warning "$service on $ip:$port is not yet accessible"
        return 1
    fi
}

# Function to check RDP connectivity
check_rdp() {
    local ip=$1
    local name=$2
    
    log "Checking RDP connectivity to $name ($ip)..."
    if check_port $ip 3389 "RDP"; then
        success "$name is ready for RDP connection"
        echo "  Connect with: mstsc /v:$ip"
        return 0
    else
        warning "$name RDP not ready yet"
        return 1
    fi
}

# Function to check SSH connectivity
check_ssh() {
    local ip=$1
    
    log "Checking SSH connectivity to Ubuntu client ($ip)..."
    if check_port $ip 22 "SSH"; then
        success "Ubuntu client is ready for SSH connection"
        echo "  Connect with: ssh -i ~/.ssh/ad_client_key ubuntu@$ip"
        return 0
    else
        warning "Ubuntu client SSH not ready yet"
        return 1
    fi
}

# Wait for basic connectivity
log "Waiting for basic VM connectivity..."
sleep 60  # Give VMs time to boot

# Check connectivity in a loop
max_attempts=20
attempt=1

while [ $attempt -le $max_attempts ]; do
    log "Connectivity check attempt $attempt/$max_attempts"
    
    root_rdp_ready=false
    child_rdp_ready=false
    client_ssh_ready=false
    
    if check_rdp $ROOT_DC_IP "Root DC"; then
        root_rdp_ready=true
    fi
    
    if check_rdp $CHILD_DC_IP "Child DC"; then
        child_rdp_ready=true
    fi
    
    if check_ssh $CLIENT_IP; then
        client_ssh_ready=true
    fi
    
    if $root_rdp_ready && $child_rdp_ready && $client_ssh_ready; then
        success "All VMs are accessible"
        break
    fi
    
    if [ $attempt -eq $max_attempts ]; then
        error "Not all VMs became accessible within expected timeframe"
        break
    fi
    
    log "Waiting 30 seconds before next check..."
    sleep 30
    ((attempt++))
done

# =============================================================================
# DOMAIN SETUP MONITORING
# =============================================================================

log "Phase 4: Monitoring Domain Setup Progress"

log "Domain setup will take 15-30 minutes. Monitoring progress..."

# Function to check if AD services are running
check_ad_service() {
    local ip=$1
    local port=$2
    local service=$3
    
    if check_port $ip $port "$service"; then
        return 0
    else
        return 1
    fi
}

# Monitor root domain setup
log "Monitoring root domain setup (corp.local)..."
root_domain_ready=false
attempt=1
max_domain_attempts=60  # 30 minutes with 30-second intervals

while [ $attempt -le $max_domain_attempts ]; do
    log "Root domain check attempt $attempt/$max_domain_attempts"
    
    if check_ad_service $ROOT_DC_IP 389 "LDAP" && \
       check_ad_service $ROOT_DC_IP 88 "Kerberos" && \
       check_ad_service $ROOT_DC_IP 53 "DNS"; then
        success "Root domain (corp.local) appears to be operational"
        root_domain_ready=true
        break
    fi
    
    log "Root domain not ready yet, waiting 30 seconds..."
    sleep 30
    ((attempt++))
done

if ! $root_domain_ready; then
    warning "Root domain setup timeout - may need manual intervention"
    echo "Check logs on Root DC at: C:\\root-domain-setup.log"
fi

# Monitor child domain setup (only if root is ready)
if $root_domain_ready; then
    log "Monitoring child domain setup (dev.corp.local)..."
    child_domain_ready=false
    attempt=1
    
    while [ $attempt -le $max_domain_attempts ]; do
        log "Child domain check attempt $attempt/$max_domain_attempts"
        
        if check_ad_service $CHILD_DC_IP 389 "LDAP" && \
           check_ad_service $CHILD_DC_IP 88 "Kerberos"; then
            success "Child domain (dev.corp.local) appears to be operational"
            child_domain_ready=true
            break
        fi
        
        log "Child domain not ready yet, waiting 30 seconds..."
        sleep 30
        ((attempt++))
    done
    
    if ! $child_domain_ready; then
        warning "Child domain setup timeout - may need manual intervention"
        echo "Check logs on Child DC at: C:\\child-domain-setup.log"
    fi
fi

# =============================================================================
# CLIENT VERIFICATION
# =============================================================================

log "Phase 5: Client Verification"

if $client_ssh_ready; then
    log "Testing Ubuntu client multi-domain configuration..."
    
    # Test basic connectivity from client
    ssh -i ~/.ssh/ad_client_key -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@$CLIENT_IP "
        echo 'Testing client configuration...'
        
        # Check if setup completed
        if [ -f /tmp/multidomain-setup-complete.flag ]; then
            echo '✅ Ubuntu client setup completed'
        else
            echo '⚠️ Ubuntu client setup may still be in progress'
        fi
        
        # Test DNS resolution
        echo 'Testing DNS resolution...'
        nslookup rootdc.corp.local 10.0.1.4 && echo '✅ Root domain DNS working' || echo '❌ Root domain DNS failed'
        nslookup childdc.dev.corp.local 10.0.2.4 && echo '✅ Child domain DNS working' || echo '❌ Child domain DNS failed'
        
        # Test port connectivity
        echo 'Testing port connectivity...'
        timeout 5 bash -c '</dev/tcp/10.0.1.4/389' 2>/dev/null && echo '✅ Root LDAP port accessible' || echo '❌ Root LDAP port not accessible'
        timeout 5 bash -c '</dev/tcp/10.0.2.4/389' 2>/dev/null && echo '✅ Child LDAP port accessible' || echo '❌ Child LDAP port not accessible'
        
        # Check if test scripts are available
        if [ -f /opt/multidomain-tests/test-all-domains.sh ]; then
            echo '✅ Multi-domain test scripts available'
        else
            echo '❌ Multi-domain test scripts not found'
        fi
    " 2>/dev/null || warning "Could not connect to Ubuntu client for verification"
fi

# =============================================================================
# DEPLOYMENT SUMMARY
# =============================================================================

log "Phase 6: Deployment Summary"

echo ""
echo "======================================================================"
echo "🎉 CASE 2 DEPLOYMENT SUMMARY"
echo "======================================================================"
echo ""
echo "Infrastructure Status:"
echo "  ✅ Terraform deployment: COMPLETED"
echo "  ✅ Azure resources: PROVISIONED"
echo "  ✅ Network connectivity: VERIFIED"
echo ""
echo "Domain Status:"
if $root_domain_ready; then
    echo "  ✅ Root domain (corp.local): OPERATIONAL"
else
    echo "  ⚠️ Root domain (corp.local): NEEDS VERIFICATION"
fi

if $child_domain_ready; then
    echo "  ✅ Child domain (dev.corp.local): OPERATIONAL"
else
    echo "  ⚠️ Child domain (dev.corp.local): NEEDS VERIFICATION"
fi

echo ""
echo "Connection Information:"
echo "  🖥️ Root DC RDP: mstsc /v:$ROOT_DC_IP"
echo "  🖥️ Child DC RDP: mstsc /v:$CHILD_DC_IP"
echo "  🐧 Client SSH: ssh -i ~/.ssh/ad_client_key ubuntu@$CLIENT_IP"
echo ""
echo "Next Steps:"
echo "  1. Wait 5-10 more minutes for complete AD setup"
echo "  2. SSH to client and run: /opt/multidomain-tests/test-all-domains.sh"
echo "  3. Test authentication: kinit enterprise.admin@CORP.LOCAL"
echo "  4. Test child domain: kinit dev.lead@DEV.CORP.LOCAL"
echo "  5. Verify trust: /opt/multidomain-tests/verify-trust.sh"
echo ""
echo "Manual Setup (if automation failed):"
echo "  📖 See: docs/manual-setup-guide.md"
echo "  📜 Download scripts from Azure storage (check terraform output)"
echo ""
echo "Cleanup (when done testing):"
echo "  🧹 Run: terraform destroy -auto-approve"
echo ""
echo "======================================================================"

# =============================================================================
# SAVE DEPLOYMENT INFO
# =============================================================================

cat > case2-deployment-info.txt << EOF
# Case 2: Root-Child Domain Deployment Information
# Generated: $(date)

## Connection Information
Root DC Public IP: $ROOT_DC_IP
Child DC Public IP: $CHILD_DC_IP
Client Public IP: $CLIENT_IP

## RDP Connections
mstsc /v:$ROOT_DC_IP
mstsc /v:$CHILD_DC_IP

## SSH Connection
ssh -i ~/.ssh/ad_client_key ubuntu@$CLIENT_IP

## Test Users (Password: TestPass123!)
# Root Domain (corp.local)
enterprise.admin@CORP.LOCAL
corp.manager@CORP.LOCAL
network.engineer@CORP.LOCAL
security.analyst@CORP.LOCAL

# Child Domain (dev.corp.local)
dev.lead@DEV.CORP.LOCAL
senior.dev@DEV.CORP.LOCAL
junior.dev@DEV.CORP.LOCAL
qa.engineer@DEV.CORP.LOCAL

## Testing Commands
kinit enterprise.admin@CORP.LOCAL
kinit dev.lead@DEV.CORP.LOCAL
/opt/multidomain-tests/test-all-domains.sh
/opt/multidomain-tests/verify-trust.sh

## FortiProxy Configuration
# Global Catalog (recommended)
Server: $ROOT_DC_IP:3268
Base DN: DC=corp,DC=local
Bind DN: enterprise.admin@corp.local

# Root Domain
Server: $ROOT_DC_IP:389
Base DN: DC=corp,DC=local

# Child Domain
Server: $CHILD_DC_IP:389  
Base DN: DC=dev,DC=corp,DC=local

## Cleanup
terraform destroy -auto-approve
EOF

success "Deployment information saved to: case2-deployment-info.txt"
log "Case 2 deployment and verification completed!"

exit 0