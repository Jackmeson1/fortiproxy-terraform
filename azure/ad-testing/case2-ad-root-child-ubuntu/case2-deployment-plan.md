# 🎯 Case 2 Deployment & Verification Plan

## 🚀 Deployment Commands (Real Environment)

```bash
# 1. Configure Azure credentials
export ARM_SUBSCRIPTION_ID="50818092-54c7-4dca-b161-8a3923f745e6"
export ARM_CLIENT_ID="d99abd26-9c5a-4fd3-9e3b-e5c7b9e8a4e3"
export ARM_CLIENT_SECRET="9aG8Q~j3XzR7qN2kM9bP4vL8nE6wF1tC5rA0sD"
export ARM_TENANT_ID="88e04d3f-6a2d-4b5c-9e4d-2e8f5a7b9c1d"

# 2. Generate SSH key for client access
ssh-keygen -t rsa -b 4096 -f ~/.ssh/case2_key
# Update terraform.tfvars with public key

# 3. Deploy infrastructure
terraform init
terraform plan -out=case2.tfplan
terraform apply case2.tfplan

# 4. Wait for automation (20-30 minutes)
./deploy-and-verify.sh

# 5. Connect to client and verify
CLIENT_IP=$(terraform output -raw client_public_ip)
ssh -i ~/.ssh/case2_key ubuntu@$CLIENT_IP

# 6. Run verification on client
./test-case2-verification.sh
```

## 🎫 Critical Verification Points

### Phase 1: Infrastructure Verification
- [ ] Root DC accessible (RDP port 3389)
- [ ] Child DC accessible (RDP port 3389) 
- [ ] Ubuntu client accessible (SSH port 22)
- [ ] VNet connectivity between subnets

### Phase 2: Domain Services Verification
- [ ] Root domain LDAP (port 389) operational
- [ ] Root domain Kerberos (port 88) operational
- [ ] Root domain DNS (port 53) operational
- [ ] Child domain LDAP (port 389) operational
- [ ] Child domain Kerberos (port 88) operational
- [ ] Global Catalog (port 3268) operational

### Phase 3: User and Trust Verification
- [ ] Root domain users created (enterprise.admin, corp.manager, etc.)
- [ ] Child domain users created (dev.lead, senior.dev, etc.)
- [ ] Parent-child trust relationship established
- [ ] Cross-domain group memberships working

### Phase 4: Client Configuration Verification
- [ ] Multi-domain Kerberos configuration (/etc/krb5.conf)
- [ ] Multi-domain LDAP configuration (/etc/ldap/ldap.conf)
- [ ] DNS resolution for both domains
- [ ] Network connectivity to both DCs

### Phase 5: **THE MAIN CHALLENGE** - Ticket Acquisition
- [ ] **Root domain ticket**: `kinit enterprise.admin@CORP.LOCAL`
- [ ] **Child domain ticket**: `kinit dev.lead@DEV.CORP.LOCAL`
- [ ] **Ticket verification**: `klist` shows correct principal
- [ ] **Cross-domain access**: Root ticket can query child domain
- [ ] **Trust verification**: `klist -T` shows trusted realms

## 🧪 Verification Commands

### Root Domain Ticket Test
```bash
# Clear any existing tickets
kdestroy

# Acquire root domain ticket
kinit enterprise.admin@CORP.LOCAL
# Password: TestPass123!

# Verify ticket
klist
# Should show: Default principal: enterprise.admin@CORP.LOCAL

# Test LDAP with ticket
ldapwhoami -H ldap://10.0.1.4 -Y GSSAPI
```

### Child Domain Ticket Test
```bash
# Clear tickets
kdestroy

# Acquire child domain ticket  
kinit dev.lead@DEV.CORP.LOCAL
# Password: TestPass123!

# Verify ticket
klist
# Should show: Default principal: dev.lead@DEV.CORP.LOCAL

# Test LDAP with ticket
ldapwhoami -H ldap://10.0.2.4 -Y GSSAPI
```

### Cross-Domain Authentication Test
```bash
# Get root domain ticket
kinit enterprise.admin@CORP.LOCAL

# Query child domain using root credentials
ldapsearch -H ldap://10.0.2.4 -Y GSSAPI \
  -b "DC=dev,DC=corp,DC=local" \
  "(objectClass=user)" cn

# Should succeed due to trust relationship
```

### Trust Verification Test
```bash
# Get any valid ticket
kinit enterprise.admin@CORP.LOCAL

# Check trusted realms
klist -T
# Should show both CORP.LOCAL and DEV.CORP.LOCAL
```

## 🎯 Success Criteria

The deployment is considered **SUCCESSFUL** if:

1. ✅ **Infrastructure deploys** without errors
2. ✅ **Both domains operational** (LDAP/Kerberos services responding)
3. ✅ **Ubuntu client configured** for multi-domain authentication
4. ✅ **Root domain tickets work** (`kinit enterprise.admin@CORP.LOCAL`)
5. ✅ **Child domain tickets work** (`kinit dev.lead@DEV.CORP.LOCAL`)
6. ✅ **Cross-domain queries work** (trust relationship functional)
7. ✅ **Global Catalog accessible** (forest-wide searches work)

## 🚨 Troubleshooting

### If Root Domain Ticket Fails
```bash
# Check Kerberos configuration
cat /etc/krb5.conf | grep -A 10 CORP.LOCAL

# Test DNS resolution
nslookup rootdc.corp.local 10.0.1.4

# Test Kerberos port
telnet 10.0.1.4 88

# Check user exists (LDAP query)
ldapsearch -x -h 10.0.1.4 -b "DC=corp,DC=local" \
  "(sAMAccountName=enterprise.admin)"
```

### If Child Domain Ticket Fails
```bash
# Check child domain configuration
cat /etc/krb5.conf | grep -A 10 DEV.CORP.LOCAL

# Test child DNS resolution
nslookup childdc.dev.corp.local 10.0.2.4

# Test child Kerberos port
telnet 10.0.2.4 88

# Verify trust from root domain (if accessible)
# On Windows: nltest /domain_trusts /v
```

### If Cross-Domain Access Fails
```bash
# Verify trust relationship
klist -T

# Check if GSSAPI is working
ldapsearch -H ldap://10.0.1.4 -Y GSSAPI -b "" -s base

# Test with explicit credentials
ldapsearch -H ldap://10.0.2.4 \
  -D "enterprise.admin@corp.local" -W \
  -b "DC=dev,DC=corp,DC=local" "(objectClass=user)"
```

## 📊 Expected Timeline

- **Infrastructure Deployment**: 5-10 minutes
- **Root Domain Setup**: 15-20 minutes
- **Child Domain Setup**: 15-20 minutes
- **Client Configuration**: 5-10 minutes
- **Trust Establishment**: Automatic (part of child domain setup)
- **Total Time**: 40-60 minutes

## 🏆 Challenge Completion

The challenge is **COMPLETED** when you can successfully:

1. SSH to the Ubuntu client
2. Run `kinit enterprise.admin@CORP.LOCAL` and get a valid ticket
3. Run `kinit dev.lead@DEV.CORP.LOCAL` and get a valid ticket
4. Use both tickets for LDAP authentication
5. Perform cross-domain queries successfully

This proves the complete root-child domain architecture with multi-domain authentication is working correctly!
