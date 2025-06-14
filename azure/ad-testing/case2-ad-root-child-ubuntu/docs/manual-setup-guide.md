# 🔧 Manual Setup Guide - Case 2: Root-Child Domain

> **Fallback instructions for manual setup when automation fails**

## 📋 Pre-Setup Verification

Before starting manual setup, verify infrastructure is deployed:

```bash
# Check Terraform deployment status
terraform output

# Verify VMs are running
az vm list --resource-group case2-root-child-rg --output table
```

## 🏢 Root Domain Controller Setup

### Step 1: Connect to Root DC

```bash
# Get Root DC public IP from Terraform output
ROOT_DC_IP=$(terraform output -raw root_dc_public_ip)

# RDP to Root Domain Controller
mstsc /v:$ROOT_DC_IP
# Username: azureuser
# Password: [from terraform.tfvars]
```

### Step 2: Download and Execute Root Domain Script

```powershell
# Download the script from storage
$scriptUrl = "https://[storage-account].blob.core.windows.net/automation-scripts/setup-root-domain.ps1"
Invoke-WebRequest -Uri $scriptUrl -OutFile "C:\setup-root-domain.ps1"

# Execute root domain setup
Set-ExecutionPolicy Unrestricted -Force
& C:\setup-root-domain.ps1 -DomainName "corp.local" -AdminPassword "YourPasswordHere"
```

### Step 3: Monitor Root Domain Setup

```powershell
# Monitor setup progress
Get-Content "C:\root-domain-setup.log" -Wait

# After reboot, check post-reboot log
Get-Content "C:\root-domain-postreboot.log" -Wait

# Verify domain is ready
Get-ADDomain -Server "corp.local"
Get-ADUser -Filter * -Server "corp.local" | Select Name, SamAccountName
```

## 🏗️ Child Domain Controller Setup

### Step 1: Wait for Root Domain Completion

**⚠️ CRITICAL: Wait until root domain is fully operational before proceeding**

```powershell
# Test root domain from child DC
nslookup corp.local 10.0.1.4
```

### Step 2: Connect to Child DC

```bash
# Get Child DC public IP
CHILD_DC_IP=$(terraform output -raw child_dc_public_ip)

# RDP to Child Domain Controller  
mstsc /v:$CHILD_DC_IP
```

### Step 3: Execute Child Domain Setup

```powershell
# Download the script
$scriptUrl = "https://[storage-account].blob.core.windows.net/automation-scripts/setup-child-domain.ps1"
Invoke-WebRequest -Uri $scriptUrl -OutFile "C:\setup-child-domain.ps1"

# Execute child domain setup
& C:\setup-child-domain.ps1 `
  -RootDomainName "corp.local" `
  -ChildDomainName "dev.corp.local" `
  -AdminPassword "YourPasswordHere" `
  -RootDcIp "10.0.1.4"
```

### Step 4: Verify Child Domain and Trust

```powershell
# Monitor child domain setup
Get-Content "C:\child-domain-setup.log" -Wait
Get-Content "C:\child-domain-postreboot.log" -Wait

# Verify child domain
Get-ADDomain -Server "dev.corp.local"

# Verify trust relationship
Get-ADTrust -Filter * -Server "dev.corp.local"
nltest /domain_trusts /v
```

## 🐧 Ubuntu Client Setup

### Step 1: Connect to Ubuntu Client

```bash
# Get client public IP
CLIENT_IP=$(terraform output -raw client_public_ip)

# SSH to Ubuntu client
ssh -i ~/.ssh/ad_client_key ubuntu@$CLIENT_IP
```

### Step 2: Execute Multi-Domain Client Setup

```bash
# Download the script
sudo wget https://[storage-account].blob.core.windows.net/automation-scripts/setup-client-multidomain.sh -O /tmp/setup-client.sh

# Make executable and run
sudo chmod +x /tmp/setup-client.sh
sudo /tmp/setup-client.sh
```

### Step 3: Verify Client Configuration

```bash
# Check setup log
sudo tail -f /var/log/multidomain-client-setup.log

# Test multi-domain functionality
/opt/multidomain-tests/test-all-domains.sh
```

## 🧪 Verification and Testing

### Multi-Domain Authentication Tests

```bash
# Test root domain authentication
kinit enterprise.admin@CORP.LOCAL
# Password: TestPass123!

# Test child domain authentication  
kinit dev.lead@DEV.CORP.LOCAL
# Password: TestPass123!

# Test cross-domain functionality
/opt/multidomain-tests/test-cross-domain.sh

# Verify trust relationships
/opt/multidomain-tests/verify-trust.sh
```

### LDAP Testing

```bash
# Root domain LDAP
ldapwhoami -H ldap://10.0.1.4 -D "enterprise.admin@corp.local" -W

# Child domain LDAP
ldapwhoami -H ldap://10.0.2.4 -D "dev.lead@dev.corp.local" -W

# Global Catalog search
ldapsearch -H ldap://10.0.1.4:3268 -D "enterprise.admin@corp.local" -W \
  -b "DC=corp,DC=local" "(objectClass=user)" cn sAMAccountName
```

## 🚨 Troubleshooting Common Issues

### Root Domain Issues

```powershell
# Check AD services
Get-Service ADWS,KDC,NTDS,DNS | Format-Table Name,Status
Get-EventLog -LogName "Directory Service" -Newest 10

# Restart AD services if needed
Restart-Service ADWS,KDC,NTDS -Force
```

### Child Domain Issues

```powershell
# Check trust relationship
nltest /server:childdc.dev.corp.local /sc_query:corp.local

# Reset trust if needed
netdom trust dev.corp.local /domain:corp.local /reset
```

### Client Issues

```bash
# Fix DNS issues
sudo systemctl restart systemd-resolved
sudo chattr -i /etc/resolv.conf
sudo echo "nameserver 10.0.1.4" > /etc/resolv.conf
sudo echo "nameserver 10.0.2.4" >> /etc/resolv.conf
sudo chattr +i /etc/resolv.conf

# Restart authentication services
sudo systemctl restart nscd
```

## 🕒 Timing Considerations

**Recommended Setup Timeline:**
1. **Root Domain**: 15-20 minutes (includes reboot)
2. **Wait Period**: 5 minutes (let root domain stabilize)
3. **Child Domain**: 15-20 minutes (includes reboot and trust setup)
4. **Client Setup**: 5-10 minutes
5. **Total Time**: 40-55 minutes

## 📞 Emergency Recovery

### Complete Reset Process

```bash
# If everything fails, destroy and redeploy
terraform destroy -auto-approve
terraform apply -auto-approve

# Then follow manual setup from beginning
```

### Partial Recovery Options

```bash
# Reset just the domain controllers
az vm restart --resource-group case2-root-child-rg --name case2-root-child-rg-root-dc
az vm restart --resource-group case2-root-child-rg --name case2-root-child-rg-child-dc

# Re-run specific setup scripts
```

## ✅ Success Indicators

**Root Domain Ready:**
- ✅ Forest created successfully
- ✅ Enterprise users created
- ✅ DNS working for corp.local
- ✅ Global Catalog operational

**Child Domain Ready:**
- ✅ Child domain joined to forest
- ✅ Development users created
- ✅ Trust relationship established
- ✅ Cross-domain authentication working

**Client Ready:**
- ✅ Multi-domain Kerberos working
- ✅ LDAP queries to both domains successful
- ✅ Global Catalog searches working
- ✅ All test scripts passing

---

**💡 Pro Tip**: Always wait for each step to complete fully before proceeding to the next. Domain controller operations are sequential and can't be rushed!