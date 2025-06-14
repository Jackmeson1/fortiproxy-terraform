# ✅ Case 2: Root-Child Domain Validation Checklist

## 🎯 Pre-Deployment Checklist

- [ ] Azure credentials configured in terraform.tfvars
- [ ] SSH key generated and public key added to terraform.tfvars
- [ ] admin_source_ip restricted to your IP (security)
- [ ] Resource group name unique to avoid conflicts
- [ ] VM sizes appropriate for testing (Standard_B2ms minimum)

## 🚀 Deployment Validation

- [ ] `terraform init` completes successfully
- [ ] `terraform plan` shows expected resources
- [ ] `terraform apply` completes without errors
- [ ] All 5 VMs deployed (root DC, child DC, client)
- [ ] Public IPs assigned and accessible

## 🌐 Network Connectivity Validation

- [ ] Root DC RDP (port 3389) accessible
- [ ] Child DC RDP (port 3389) accessible  
- [ ] Ubuntu client SSH (port 22) accessible
- [ ] Inter-subnet communication working

## 🏢 Root Domain Validation

- [ ] Root DC boots and Windows login works
- [ ] Active Directory Domain Services installed
- [ ] Forest created (corp.local)
- [ ] DNS service operational
- [ ] LDAP service (port 389) responding
- [ ] Kerberos service (port 88) responding
- [ ] Global Catalog (port 3268) responding
- [ ] Enterprise users created (enterprise.admin, corp.manager, etc.)
- [ ] Forest-wide security groups created

## 🏗️ Child Domain Validation

- [ ] Child DC boots and Windows login works
- [ ] Active Directory Domain Services installed
- [ ] Child domain joined (dev.corp.local)
- [ ] DNS service operational
- [ ] LDAP service (port 389) responding
- [ ] Kerberos service (port 88) responding
- [ ] Development users created (dev.lead, senior.dev, etc.)
- [ ] Domain-specific security groups created

## 🤝 Trust Relationship Validation

- [ ] Parent-child trust automatically established
- [ ] Trust is two-way and transitive
- [ ] Cross-domain name resolution working
- [ ] Trust visible via Windows tools (nltest /domain_trusts)

## 🐧 Ubuntu Client Validation

- [ ] Ubuntu boots and SSH login works
- [ ] Multi-domain DNS configuration (/etc/resolv.conf)
- [ ] Multi-realm Kerberos configuration (/etc/krb5.conf)
- [ ] LDAP client configuration (/etc/ldap/ldap.conf)
- [ ] Testing scripts deployed (/opt/multidomain-tests/)
- [ ] Network connectivity to both DCs

## 🎫 **CORE CHALLENGE: Kerberos Ticket Acquisition**

### Root Domain Ticket Test
- [ ] `kdestroy` clears existing tickets
- [ ] `kinit enterprise.admin@CORP.LOCAL` succeeds
- [ ] Password `TestPass123!` accepted
- [ ] `klist` shows enterprise.admin@CORP.LOCAL principal
- [ ] Ticket has reasonable expiry time
- [ ] No error messages in ticket acquisition

### Child Domain Ticket Test
- [ ] `kdestroy` clears existing tickets
- [ ] `kinit dev.lead@DEV.CORP.LOCAL` succeeds
- [ ] Password `TestPass123!` accepted
- [ ] `klist` shows dev.lead@DEV.CORP.LOCAL principal
- [ ] Ticket has reasonable expiry time
- [ ] No error messages in ticket acquisition

### Multi-User Ticket Test
- [ ] `kinit corp.manager@CORP.LOCAL` works
- [ ] `kinit network.engineer@CORP.LOCAL` works
- [ ] `kinit senior.dev@DEV.CORP.LOCAL` works
- [ ] `kinit qa.engineer@DEV.CORP.LOCAL` works

## 🔐 LDAP Authentication Validation

### Root Domain LDAP
- [ ] Anonymous LDAP query works
- [ ] Authenticated LDAP with ticket works
- [ ] `ldapwhoami -H ldap://10.0.1.4 -Y GSSAPI` succeeds
- [ ] User searches return expected results
- [ ] Group membership queries work

### Child Domain LDAP
- [ ] Anonymous LDAP query works
- [ ] Authenticated LDAP with ticket works
- [ ] `ldapwhoami -H ldap://10.0.2.4 -Y GSSAPI` succeeds
- [ ] User searches return expected results
- [ ] Group membership queries work

### Global Catalog LDAP
- [ ] Anonymous GC query works (port 3268)
- [ ] Authenticated GC with ticket works
- [ ] Forest-wide user searches work
- [ ] Cross-domain group queries work

## 🔗 Cross-Domain Authentication Validation

### Root → Child Access
- [ ] Get root domain ticket (`kinit enterprise.admin@CORP.LOCAL`)
- [ ] Query child domain LDAP with GSSAPI succeeds
- [ ] Can search child domain users
- [ ] Can access child domain resources

### Child → Root Access  
- [ ] Get child domain ticket (`kinit dev.lead@DEV.CORP.LOCAL`)
- [ ] Query root domain LDAP with GSSAPI succeeds
- [ ] Can search root domain users
- [ ] Can access root domain resources

### Trust Verification
- [ ] `klist -T` shows both realms as trusted
- [ ] Cross-realm ticket acquisition works
- [ ] No authentication errors in cross-domain access

## 🧪 Comprehensive Test Suite

- [ ] `/opt/multidomain-tests/test-all-domains.sh` runs successfully
- [ ] All network connectivity tests pass
- [ ] All DNS resolution tests pass
- [ ] All port connectivity tests pass
- [ ] All LDAP query tests pass
- [ ] All Kerberos tests pass

## 🎯 FortiProxy Integration Readiness

- [ ] Global Catalog accessible (for forest-wide auth)
- [ ] Domain-specific LDAP accessible
- [ ] Service accounts available (svc.fortiproxy, svc.enterprise)
- [ ] Group-based access control functional
- [ ] Search filters working for different user types

## 🏆 Success Confirmation

**The deployment is SUCCESSFUL if ALL of the following work:**

1. ✅ `ssh -i ~/.ssh/case2_key ubuntu@<CLIENT-IP>` connects
2. ✅ `kinit enterprise.admin@CORP.LOCAL` acquires ticket
3. ✅ `kinit dev.lead@DEV.CORP.LOCAL` acquires ticket  
4. ✅ `klist` shows correct principals for both domains
5. ✅ Cross-domain LDAP queries work with tickets
6. ✅ `/opt/multidomain-tests/test-all-domains.sh` passes all tests

## 🚨 Failure Scenarios & Solutions

### Ticket Acquisition Fails
- Check DNS resolution to domain controllers
- Verify Kerberos port (88) accessibility
- Check user account exists in domain
- Verify password hasn't been changed
- Check time synchronization between client and DCs

### Cross-Domain Access Fails
- Verify trust relationship established
- Check Global Catalog accessibility
- Verify GSSAPI mechanism working
- Check firewall rules between domains

### LDAP Authentication Fails
- Verify LDAP service running (port 389)
- Check LDAP bind credentials
- Verify user has appropriate permissions
- Check LDAP base DN configuration

---

**🎯 Challenge Complete**: When all checkboxes are ✅, Case 2 verification is successful!
