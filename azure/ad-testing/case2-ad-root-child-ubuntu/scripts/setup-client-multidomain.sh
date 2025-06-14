#!/bin/bash
# =============================================================================
# AUTOMATED UBUNTU CLIENT SETUP - Case 2: Multi-Domain Environment
# =============================================================================

set -e  # Exit on any error

# Variables from Terraform
ROOT_DOMAIN_NAME="${root_domain_name}"
CHILD_DOMAIN_NAME="${child_domain_name}"
ROOT_DOMAIN_UPPER="${root_domain_upper}"
CHILD_DOMAIN_UPPER="${child_domain_upper}"
ROOT_DC_IP="${root_dc_ip}"
CHILD_DC_IP="${child_dc_ip}"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/multidomain-client-setup.log
}

log "Starting Ubuntu client setup for multi-domain environment"
log "Root Domain: $ROOT_DOMAIN_NAME ($ROOT_DC_IP)"
log "Child Domain: $CHILD_DOMAIN_NAME ($CHILD_DC_IP)"

# =============================================================================
# SYSTEM UPDATES AND BASIC SETUP
# =============================================================================

log "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Install required packages for multi-domain support
log "Installing required packages for multi-domain authentication..."
apt-get install -y \
    krb5-user \
    krb5-config \
    libpam-krb5 \
    ldap-utils \
    libpam-ldap \
    libnss-ldap \
    nscd \
    ntp \
    ntpdate \
    dnsutils \
    net-tools \
    telnet \
    curl \
    wget \
    vim \
    htop \
    tree \
    jq \
    samba-common-bin \
    winbind

log "Required packages installed successfully"

# =============================================================================
# TIME SYNCHRONIZATION
# =============================================================================

log "Configuring time synchronization..."

# Sync time with both domain controllers
systemctl stop ntp
ntpdate -s $ROOT_DC_IP || ntpdate -s $CHILD_DC_IP || ntpdate -s pool.ntp.org
systemctl start ntp
systemctl enable ntp

log "Time synchronization configured"

# =============================================================================
# DNS CONFIGURATION FOR MULTI-DOMAIN
# =============================================================================

log "Configuring DNS for multi-domain environment..."

# Backup original resolv.conf
cp /etc/resolv.conf /etc/resolv.conf.backup

# Configure DNS with both domain controllers
cat > /etc/resolv.conf << EOF
# Multi-domain DNS configuration
nameserver $ROOT_DC_IP
nameserver $CHILD_DC_IP
search $ROOT_DOMAIN_NAME $CHILD_DOMAIN_NAME
domain $ROOT_DOMAIN_NAME
EOF

# Make resolv.conf immutable
chattr +i /etc/resolv.conf

# Add both domain controllers to hosts file
echo "$ROOT_DC_IP rootdc.$ROOT_DOMAIN_NAME rootdc" >> /etc/hosts
echo "$ROOT_DC_IP ldap.$ROOT_DOMAIN_NAME root-ldap" >> /etc/hosts
echo "$ROOT_DC_IP kerberos.$ROOT_DOMAIN_NAME root-kerberos" >> /etc/hosts
echo "$ROOT_DC_IP gc.$ROOT_DOMAIN_NAME global-catalog" >> /etc/hosts

echo "$CHILD_DC_IP childdc.$CHILD_DOMAIN_NAME childdc" >> /etc/hosts
echo "$CHILD_DC_IP dev-ldap.$CHILD_DOMAIN_NAME child-ldap" >> /etc/hosts
echo "$CHILD_DC_IP dev-kerberos.$CHILD_DOMAIN_NAME child-kerberos" >> /etc/hosts

log "Multi-domain DNS configuration completed"

# =============================================================================
# KERBEROS CONFIGURATION FOR MULTI-DOMAIN
# =============================================================================

log "Configuring Kerberos for multi-domain environment..."

# Backup original krb5.conf
cp /etc/krb5.conf /etc/krb5.conf.backup 2>/dev/null || true

# Create comprehensive Kerberos configuration for forest
cat > /etc/krb5.conf << EOF
[libdefaults]
    default_realm = $ROOT_DOMAIN_UPPER
    dns_lookup_realm = true
    dns_lookup_kdc = true
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true
    proxiable = true
    default_tkt_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 rc4-hmac
    default_tgs_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 rc4-hmac
    permitted_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 rc4-hmac

[realms]
    $ROOT_DOMAIN_UPPER = {
        kdc = rootdc.$ROOT_DOMAIN_NAME
        admin_server = rootdc.$ROOT_DOMAIN_NAME
        default_domain = $ROOT_DOMAIN_NAME
    }
    
    $CHILD_DOMAIN_UPPER = {
        kdc = childdc.$CHILD_DOMAIN_NAME
        admin_server = childdc.$CHILD_DOMAIN_NAME  
        default_domain = $CHILD_DOMAIN_NAME
    }

[domain_realm]
    .$ROOT_DOMAIN_NAME = $ROOT_DOMAIN_UPPER
    $ROOT_DOMAIN_NAME = $ROOT_DOMAIN_UPPER
    .$CHILD_DOMAIN_NAME = $CHILD_DOMAIN_UPPER
    $CHILD_DOMAIN_NAME = $CHILD_DOMAIN_UPPER
    
[capaths]
    $CHILD_DOMAIN_UPPER = {
        $ROOT_DOMAIN_UPPER = .
    }
    $ROOT_DOMAIN_UPPER = {
        $CHILD_DOMAIN_UPPER = .
    }
    
[login]
    krb4_convert = true
    krb4_get_tickets = false
EOF

log "Multi-domain Kerberos configuration completed"

# =============================================================================
# LDAP CONFIGURATION FOR MULTI-DOMAIN
# =============================================================================

log "Configuring LDAP for multi-domain environment..."

# Configure LDAP client for multi-domain
cat > /etc/ldap/ldap.conf << EOF
# Multi-domain LDAP configuration
BASE    dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g')
URI     ldap://$ROOT_DC_IP ldaps://$ROOT_DC_IP ldap://$CHILD_DC_IP ldaps://$CHILD_DC_IP

# Primary bind DN (use root domain enterprise admin)
BINDDN  cn=enterprise.admin,ou=enterprise-admins,dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g')

# TLS/SSL configuration
TLS_CACERTDIR   /etc/ssl/certs
TLS_REQCERT     allow

# Referrals - important for multi-domain
REFERRALS       on

# SASL configuration
SASL_MECH       GSSAPI
SASL_REALM      $ROOT_DOMAIN_UPPER

# Global Catalog settings for forest-wide searches
# Use port 3268 for Global Catalog on root domain controller
EOF

log "Multi-domain LDAP configuration completed"

# =============================================================================
# NSS CONFIGURATION
# =============================================================================

log "Configuring NSS for multi-domain..."

# Backup original nsswitch.conf
cp /etc/nsswitch.conf /etc/nsswitch.conf.backup

# Configure NSS to use LDAP for multi-domain
sed -i 's/^passwd:.*/passwd:         files ldap/' /etc/nsswitch.conf
sed -i 's/^group:.*/group:          files ldap/' /etc/nsswitch.conf
sed -i 's/^shadow:.*/shadow:         files ldap/' /etc/nsswitch.conf

log "Multi-domain NSS configuration completed"

# =============================================================================
# CREATE MULTI-DOMAIN TESTING SCRIPTS
# =============================================================================

log "Creating multi-domain testing scripts..."

# Create testing directory
mkdir -p /opt/multidomain-tests
chmod 755 /opt/multidomain-tests

# Create comprehensive multi-domain test script
cat > /opt/multidomain-tests/test-all-domains.sh << 'EOF'
#!/bin/bash
# =============================================================================
# COMPREHENSIVE MULTI-DOMAIN AUTHENTICATION TESTING SUITE
# =============================================================================

ROOT_DOMAIN_NAME="$ROOT_DOMAIN_NAME"
CHILD_DOMAIN_NAME="$CHILD_DOMAIN_NAME"
ROOT_DOMAIN_UPPER="$ROOT_DOMAIN_UPPER"
CHILD_DOMAIN_UPPER="$CHILD_DOMAIN_UPPER"
ROOT_DC_IP="$ROOT_DC_IP"
CHILD_DC_IP="$CHILD_DC_IP"

echo "======================================================================"
echo "Multi-Domain Authentication Testing Suite - Case 2: Root-Child"
echo "======================================================================"
echo "Root Domain: $ROOT_DOMAIN_NAME ($ROOT_DC_IP)"
echo "Child Domain: $CHILD_DOMAIN_NAME ($CHILD_DC_IP)"
echo "Test Time: $(date)"
echo "======================================================================"

# Test 1: DNS Resolution for Both Domains
echo ""
echo "🔍 Test 1: DNS Resolution"
echo "----------------------------------------------------------------------"
echo "Testing Root Domain DNS:"
nslookup rootdc.$ROOT_DOMAIN_NAME $ROOT_DC_IP
if [ $? -eq 0 ]; then
    echo "✅ Root domain DNS resolution: PASSED"
else
    echo "❌ Root domain DNS resolution: FAILED"
fi

echo ""
echo "Testing Child Domain DNS:"
nslookup childdc.$CHILD_DOMAIN_NAME $CHILD_DC_IP
if [ $? -eq 0 ]; then
    echo "✅ Child domain DNS resolution: PASSED"
else
    echo "❌ Child domain DNS resolution: FAILED"
fi

# Test 2: Network Connectivity to Both DCs
echo ""
echo "🌐 Test 2: Network Connectivity"
echo "----------------------------------------------------------------------"
echo "Testing Root DC connectivity:"
ping -c 3 $ROOT_DC_IP
if [ $? -eq 0 ]; then
    echo "✅ Root DC connectivity: PASSED"
else
    echo "❌ Root DC connectivity: FAILED"
fi

echo ""
echo "Testing Child DC connectivity:"
ping -c 3 $CHILD_DC_IP
if [ $? -eq 0 ]; then
    echo "✅ Child DC connectivity: PASSED"
else
    echo "❌ Child DC connectivity: FAILED"
fi

# Test 3: LDAP Port Connectivity
echo ""
echo "🔗 Test 3: LDAP Port Connectivity"
echo "----------------------------------------------------------------------"
echo "Testing Root DC LDAP ports:"
timeout 5 bash -c "</dev/tcp/$ROOT_DC_IP/389" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Root DC LDAP port 389: OPEN"
else
    echo "❌ Root DC LDAP port 389: CLOSED"
fi

timeout 5 bash -c "</dev/tcp/$ROOT_DC_IP/3268" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Root DC Global Catalog port 3268: OPEN"
else
    echo "❌ Root DC Global Catalog port 3268: CLOSED"
fi

echo ""
echo "Testing Child DC LDAP ports:"
timeout 5 bash -c "</dev/tcp/$CHILD_DC_IP/389" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Child DC LDAP port 389: OPEN"
else
    echo "❌ Child DC LDAP port 389: CLOSED"
fi

# Test 4: Kerberos Port Connectivity
echo ""
echo "🎫 Test 4: Kerberos Port Connectivity"
echo "----------------------------------------------------------------------"
timeout 5 bash -c "</dev/tcp/$ROOT_DC_IP/88" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Root DC Kerberos port 88: OPEN"
else
    echo "❌ Root DC Kerberos port 88: CLOSED"
fi

timeout 5 bash -c "</dev/tcp/$CHILD_DC_IP/88" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Child DC Kerberos port 88: OPEN"
else
    echo "❌ Child DC Kerberos port 88: CLOSED"
fi

# Test 5: LDAP Anonymous Queries
echo ""
echo "📂 Test 5: LDAP Anonymous Queries"
echo "----------------------------------------------------------------------"
echo "Testing Root Domain LDAP:"
ldapsearch -x -h $ROOT_DC_IP -b "dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g')" -s base "(objectclass=*)" 2>/dev/null | head -5
if [ $? -eq 0 ]; then
    echo "✅ Root domain LDAP query: PASSED"
else
    echo "❌ Root domain LDAP query: FAILED"
fi

echo ""
echo "Testing Child Domain LDAP:"
ldapsearch -x -h $CHILD_DC_IP -b "dc=$(echo $CHILD_DOMAIN_NAME | sed 's/\./,dc=/g')" -s base "(objectclass=*)" 2>/dev/null | head -5
if [ $? -eq 0 ]; then
    echo "✅ Child domain LDAP query: PASSED"
else
    echo "❌ Child domain LDAP query: FAILED"
fi

echo ""
echo "Testing Global Catalog:"
ldapsearch -x -h $ROOT_DC_IP -p 3268 -b "dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g')" -s base "(objectclass=*)" 2>/dev/null | head -5
if [ $? -eq 0 ]; then
    echo "✅ Global Catalog query: PASSED"
else
    echo "❌ Global Catalog query: FAILED"
fi

echo ""
echo "======================================================================"
echo "Interactive Multi-Domain Tests (require user input):"
echo "======================================================================"
echo ""
echo "🎫 Root Domain Kerberos Authentication:"
echo "   Run: kinit enterprise.admin@$ROOT_DOMAIN_UPPER"
echo "   Run: kinit corp.manager@$ROOT_DOMAIN_UPPER"
echo "   Run: kinit network.engineer@$ROOT_DOMAIN_UPPER"
echo "   Password: TestPass123!"
echo ""
echo "🎫 Child Domain Kerberos Authentication:"
echo "   Run: kinit dev.lead@$CHILD_DOMAIN_UPPER"
echo "   Run: kinit senior.dev@$CHILD_DOMAIN_UPPER"
echo "   Run: kinit qa.engineer@$CHILD_DOMAIN_UPPER"
echo "   Password: TestPass123!"
echo ""
echo "🔐 Root Domain LDAP Tests:"
echo "   Run: ldapwhoami -H ldap://$ROOT_DC_IP -D \"enterprise.admin@$ROOT_DOMAIN_NAME\" -W"
echo "   Run: ldapsearch -H ldap://$ROOT_DC_IP -D \"enterprise.admin@$ROOT_DOMAIN_NAME\" -W \\"
echo "        -b \"dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g')\" \"(objectClass=user)\" cn sAMAccountName"
echo ""
echo "🔐 Child Domain LDAP Tests:"
echo "   Run: ldapwhoami -H ldap://$CHILD_DC_IP -D \"dev.lead@$CHILD_DOMAIN_NAME\" -W"
echo "   Run: ldapsearch -H ldap://$CHILD_DC_IP -D \"dev.lead@$CHILD_DOMAIN_NAME\" -W \\"
echo "        -b \"dc=$(echo $CHILD_DOMAIN_NAME | sed 's/\./,dc=/g')\" \"(objectClass=user)\" cn sAMAccountName"
echo ""
echo "🌐 Global Catalog Forest-Wide Search:"
echo "   Run: ldapsearch -H ldap://$ROOT_DC_IP:3268 -D \"enterprise.admin@$ROOT_DOMAIN_NAME\" -W \\"
echo "        -b \"dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g')\" \"(objectClass=user)\" cn sAMAccountName"
echo ""
echo "🔗 Cross-Domain Authentication Test:"
echo "   1. Get ticket from root domain: kinit enterprise.admin@$ROOT_DOMAIN_UPPER"
echo "   2. Query child domain: ldapsearch -H ldap://$CHILD_DC_IP -Y GSSAPI \\"
echo "      -b \"dc=$(echo $CHILD_DOMAIN_NAME | sed 's/\./,dc=/g')\" \"(objectClass=user)\""
echo ""
echo "🔒 Domain Trust Verification:"
echo "   Run: /opt/multidomain-tests/verify-trust.sh"
echo ""
echo "======================================================================"
echo "Test completed: $(date)"
echo "======================================================================"
EOF

chmod +x /opt/multidomain-tests/test-all-domains.sh

# Create domain-specific test scripts
cat > /opt/multidomain-tests/test-root-domain.sh << 'EOF'
#!/bin/bash
echo "Testing Root Domain Authentication..."
echo "Root Domain: $ROOT_DOMAIN_NAME"
echo "Available root domain users:"
echo "- enterprise.admin@$ROOT_DOMAIN_UPPER (Enterprise Admin)"
echo "- corp.manager@$ROOT_DOMAIN_UPPER (Corporate Manager)"
echo "- network.engineer@$ROOT_DOMAIN_UPPER (Network Engineer)"
echo "- security.analyst@$ROOT_DOMAIN_UPPER (Security Analyst)"
echo ""
echo "Password for all users: TestPass123!"
echo ""
echo "Root domain test commands:"
echo "kinit enterprise.admin@$ROOT_DOMAIN_UPPER"
echo "ldapwhoami -H ldap://$ROOT_DC_IP -D \"enterprise.admin@$ROOT_DOMAIN_NAME\" -W"
echo "ldapsearch -H ldap://$ROOT_DC_IP:3268 -D \"enterprise.admin@$ROOT_DOMAIN_NAME\" -W -b \"dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g')\" \"(objectClass=user)\""
EOF

chmod +x /opt/multidomain-tests/test-root-domain.sh

cat > /opt/multidomain-tests/test-child-domain.sh << 'EOF'
#!/bin/bash
echo "Testing Child Domain Authentication..."
echo "Child Domain: $CHILD_DOMAIN_NAME"
echo "Available child domain users:"
echo "- dev.lead@$CHILD_DOMAIN_UPPER (Development Team Lead)"
echo "- senior.dev@$CHILD_DOMAIN_UPPER (Senior Developer)"
echo "- junior.dev@$CHILD_DOMAIN_UPPER (Junior Developer)"
echo "- qa.engineer@$CHILD_DOMAIN_UPPER (QA Engineer)"
echo "- test.user1@$CHILD_DOMAIN_UPPER (Test User 1)"
echo "- test.user2@$CHILD_DOMAIN_UPPER (Test User 2)"
echo ""
echo "Password for all users: TestPass123!"
echo ""
echo "Child domain test commands:"
echo "kinit dev.lead@$CHILD_DOMAIN_UPPER"
echo "ldapwhoami -H ldap://$CHILD_DC_IP -D \"dev.lead@$CHILD_DOMAIN_NAME\" -W"
echo "ldapsearch -H ldap://$CHILD_DC_IP -D \"dev.lead@$CHILD_DOMAIN_NAME\" -W -b \"dc=$(echo $CHILD_DOMAIN_NAME | sed 's/\./,dc=/g')\" \"(objectClass=user)\""
EOF

chmod +x /opt/multidomain-tests/test-child-domain.sh

# Create cross-domain test script
cat > /opt/multidomain-tests/test-cross-domain.sh << 'EOF'
#!/bin/bash
echo "Testing Cross-Domain Authentication..."
echo ""
echo "Cross-domain test scenarios:"
echo "1. Root domain user accessing child domain resources"
echo "2. Child domain user with enterprise permissions"
echo "3. Global catalog searches across forest"
echo ""
echo "Test sequence:"
echo "# Get root domain ticket"
echo "kinit enterprise.admin@$ROOT_DOMAIN_UPPER"
echo ""
echo "# Query child domain using root domain credentials"
echo "ldapsearch -H ldap://$CHILD_DC_IP -Y GSSAPI -b \"dc=$(echo $CHILD_DOMAIN_NAME | sed 's/\./,dc=/g')\" \"(objectClass=user)\" cn"
echo ""
echo "# Forest-wide search using Global Catalog"
echo "ldapsearch -H ldap://$ROOT_DC_IP:3268 -Y GSSAPI -b \"dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g')\" \"(objectClass=user)\" cn"
echo ""
echo "# Verify trust relationship"
echo "echo 'Test trust with: klist -T' (shows all trusted realms)"
EOF

chmod +x /opt/multidomain-tests/test-cross-domain.sh

# Create trust verification script
cat > /opt/multidomain-tests/verify-trust.sh << 'EOF'
#!/bin/bash
echo "Verifying Domain Trust Relationships..."
echo ""
echo "Testing Kerberos realm trusts:"
klist -T 2>/dev/null || echo "No Kerberos tickets found - run kinit first"
echo ""
echo "Testing DNS-based domain discovery:"
nslookup -type=SRV _kerberos._tcp.$ROOT_DOMAIN_NAME
echo ""
nslookup -type=SRV _kerberos._tcp.$CHILD_DOMAIN_NAME
echo ""
echo "Testing cross-domain name resolution:"
nslookup rootdc.$ROOT_DOMAIN_NAME
nslookup childdc.$CHILD_DOMAIN_NAME
EOF

chmod +x /opt/multidomain-tests/verify-trust.sh

# Create FortiProxy configuration guide
cat > /opt/multidomain-tests/fortiproxy-multidomain-config.txt << EOF
# =============================================================================
# FORTIPROXY MULTI-DOMAIN CONFIGURATION - Case 2: Root-Child Architecture
# =============================================================================

Forest Structure:
- Root Domain: $ROOT_DOMAIN_NAME (10.0.1.4)
- Child Domain: $CHILD_DOMAIN_NAME (10.0.2.4)
- Trust Type: Automatic two-way transitive trust

=== ROOT DOMAIN LDAP CONFIGURATION ===
Server: $ROOT_DC_IP
Port: 389 (LDAP) or 636 (LDAPS) or 3268 (Global Catalog)
Protocol: LDAP v3
Base DN: dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g')
Bind DN: enterprise.admin@$ROOT_DOMAIN_NAME or svc.fortiproxy@$ROOT_DOMAIN_NAME
Bind Password: TestPass123!
Common Name Identifier: sAMAccountName

Root Domain Users:
- enterprise.admin@$ROOT_DOMAIN_NAME (Enterprise Admin)
- corp.manager@$ROOT_DOMAIN_NAME (Corporate Manager)
- network.engineer@$ROOT_DOMAIN_NAME (Network Engineer)
- security.analyst@$ROOT_DOMAIN_NAME (Security Analyst)

Root Domain Groups:
- CN=Corporate-Admins,OU=Corporate-Groups,dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g')
- CN=IT-Department,OU=Corporate-Groups,dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g')
- CN=Network-Engineers,OU=Corporate-Groups,dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g')
- CN=FortiProxy-Admins,OU=Corporate-Groups,dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g')

=== CHILD DOMAIN LDAP CONFIGURATION ===
Server: $CHILD_DC_IP
Port: 389 (LDAP) or 636 (LDAPS)
Protocol: LDAP v3
Base DN: dc=$(echo $CHILD_DOMAIN_NAME | sed 's/\./,dc=/g')
Bind DN: dev.lead@$CHILD_DOMAIN_NAME or svc.dev.ldap@$CHILD_DOMAIN_NAME
Bind Password: TestPass123!
Common Name Identifier: sAMAccountName

Child Domain Users:
- dev.lead@$CHILD_DOMAIN_NAME (Development Team Lead)
- senior.dev@$CHILD_DOMAIN_NAME (Senior Developer)
- junior.dev@$CHILD_DOMAIN_NAME (Junior Developer)
- qa.engineer@$CHILD_DOMAIN_NAME (QA Engineer)

Child Domain Groups:
- CN=Dev-Admins,OU=Development-Groups,dc=$(echo $CHILD_DOMAIN_NAME | sed 's/\./,dc=/g')
- CN=Dev-Users,OU=Development-Groups,dc=$(echo $CHILD_DOMAIN_NAME | sed 's/\./,dc=/g')
- CN=FortiProxy-Dev-Users,OU=Development-Groups,dc=$(echo $CHILD_DOMAIN_NAME | sed 's/\./,dc=/g')

=== GLOBAL CATALOG CONFIGURATION (FOREST-WIDE) ===
Server: $ROOT_DC_IP (Root DC only)
Port: 3268 (Global Catalog) or 3269 (Global Catalog SSL)
Base DN: dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g')
Bind DN: enterprise.admin@$ROOT_DOMAIN_NAME
Bind Password: TestPass123!
Purpose: Forest-wide user searches across all domains

Search Filters:
- All forest users: (objectClass=user)
- Root domain users: (&(objectClass=user)(userPrincipalName=*@$ROOT_DOMAIN_NAME))
- Child domain users: (&(objectClass=user)(userPrincipalName=*@$CHILD_DOMAIN_NAME))
- Enterprise admins: (memberOf=CN=Enterprise Admins,CN=Users,dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g'))
- Corporate admins: (memberOf=CN=Corporate-Admins,OU=Corporate-Groups,dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g'))
- Development users: (memberOf=CN=Dev-Users,OU=Development-Groups,dc=$(echo $CHILD_DOMAIN_NAME | sed 's/\./,dc=/g'))

Multi-Domain Authentication Scenarios:
1. Use root domain GC (port 3268) for forest-wide authentication
2. Use specific domain controllers for domain-specific authentication
3. Cross-domain group membership queries via Global Catalog
4. Trust-based authentication between domains

Test Commands:
# Forest-wide search
ldapsearch -H ldap://$ROOT_DC_IP:3268 -D "enterprise.admin@$ROOT_DOMAIN_NAME" -W -b "dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g')" "(objectClass=user)"

# Root domain specific
ldapsearch -H ldap://$ROOT_DC_IP -D "enterprise.admin@$ROOT_DOMAIN_NAME" -W -b "dc=$(echo $ROOT_DOMAIN_NAME | sed 's/\./,dc=/g')" "(objectClass=user)"

# Child domain specific  
ldapsearch -H ldap://$CHILD_DC_IP -D "dev.lead@$CHILD_DOMAIN_NAME" -W -b "dc=$(echo $CHILD_DOMAIN_NAME | sed 's/\./,dc=/g')" "(objectClass=user)"
EOF

log "Multi-domain testing scripts created successfully"

# =============================================================================
# CREATE WELCOME MESSAGE FOR MULTI-DOMAIN
# =============================================================================

cat > /etc/motd << EOF

====================================================================
🔐 MULTI-DOMAIN TESTING CLIENT - CASE 2: ROOT-CHILD ARCHITECTURE
====================================================================

Forest Structure:
├── Root Domain: $ROOT_DOMAIN_NAME ($ROOT_DC_IP)
└── Child Domain: $CHILD_DOMAIN_NAME ($CHILD_DC_IP)

Trust Relationship: Automatic two-way transitive trust (parent-child)
Client Type: Ubuntu 20.04 LTS with multi-domain Kerberos/LDAP tools

Quick Testing Commands:
  /opt/multidomain-tests/test-all-domains.sh     - Complete test suite
  /opt/multidomain-tests/test-root-domain.sh     - Root domain tests
  /opt/multidomain-tests/test-child-domain.sh    - Child domain tests
  /opt/multidomain-tests/test-cross-domain.sh    - Cross-domain tests
  /opt/multidomain-tests/verify-trust.sh         - Trust verification

Configuration Files:
  /etc/krb5.conf                                 - Multi-realm Kerberos
  /etc/ldap/ldap.conf                           - Multi-domain LDAP
  /opt/multidomain-tests/fortiproxy-multidomain-config.txt - FortiProxy guide

Root Domain Users (Password: TestPass123!):
  enterprise.admin@$ROOT_DOMAIN_UPPER           - Enterprise Administrator
  corp.manager@$ROOT_DOMAIN_UPPER               - Corporate Manager
  network.engineer@$ROOT_DOMAIN_UPPER           - Network Engineer
  security.analyst@$ROOT_DOMAIN_UPPER           - Security Analyst

Child Domain Users (Password: TestPass123!):
  dev.lead@$CHILD_DOMAIN_UPPER                  - Development Team Lead
  senior.dev@$CHILD_DOMAIN_UPPER                - Senior Developer
  qa.engineer@$CHILD_DOMAIN_UPPER               - QA Engineer

Example Multi-Domain Commands:
  kinit enterprise.admin@$ROOT_DOMAIN_UPPER     - Root domain ticket
  kinit dev.lead@$CHILD_DOMAIN_UPPER            - Child domain ticket
  klist -T                                      - Show trusted realms
  
Global Catalog Search:
  ldapsearch -H ldap://$ROOT_DC_IP:3268 -D "enterprise.admin@$ROOT_DOMAIN_NAME" -W

🚀 Deployment Status: MULTI-DOMAIN READY - Parent-Child Trust Established
====================================================================

EOF

# =============================================================================
# RESTART SERVICES
# =============================================================================

log "Restarting services for multi-domain configuration..."

systemctl restart nscd
systemctl enable nscd

log "Multi-domain services restarted successfully"

# =============================================================================
# FINAL VALIDATION
# =============================================================================

log "Performing multi-domain validation..."

# Test DNS resolution for both domains
if nslookup rootdc.$ROOT_DOMAIN_NAME $ROOT_DC_IP > /dev/null 2>&1; then
    log "✅ Root domain DNS resolution: PASSED"
else
    log "❌ Root domain DNS resolution: FAILED"
fi

if nslookup childdc.$CHILD_DOMAIN_NAME $CHILD_DC_IP > /dev/null 2>&1; then
    log "✅ Child domain DNS resolution: PASSED"
else
    log "❌ Child domain DNS resolution: FAILED"
fi

# Test network connectivity to both DCs
if ping -c 1 $ROOT_DC_IP > /dev/null 2>&1; then
    log "✅ Root DC connectivity: PASSED"
else
    log "❌ Root DC connectivity: FAILED"
fi

if ping -c 1 $CHILD_DC_IP > /dev/null 2>&1; then
    log "✅ Child DC connectivity: PASSED"
else
    log "❌ Child DC connectivity: FAILED"
fi

# =============================================================================
# COMPLETION
# =============================================================================

log "Multi-domain Ubuntu client setup completed successfully!"
log "Client is ready for multi-domain AD authentication testing"
log "Forest structure: $ROOT_DOMAIN_NAME (root) -> $CHILD_DOMAIN_NAME (child)"
log "Run '/opt/multidomain-tests/test-all-domains.sh' to start comprehensive testing"
log "Parent-child domain trust relationship will be automatically established"
log "Setup log saved to: /var/log/multidomain-client-setup.log"

echo "Multi-domain client setup completed - check /var/log/multidomain-client-setup.log for details" > /tmp/multidomain-setup-complete.flag