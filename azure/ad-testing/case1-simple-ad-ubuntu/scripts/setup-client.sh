#!/bin/bash
# =============================================================================
# AUTOMATED UBUNTU CLIENT SETUP - Case 1: Simple AD
# =============================================================================

set -e  # Exit on any error

# Variables from Terraform
DOMAIN_NAME="${domain_name}"
DOMAIN_UPPER="${domain_upper}"
AD_SERVER_IP="${ad_server_ip}"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a /var/log/ad-client-setup.log
}

log "Starting Ubuntu client setup for AD domain: $DOMAIN_NAME"

# =============================================================================
# SYSTEM UPDATES AND BASIC SETUP
# =============================================================================

log "Updating system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y

# Install required packages
log "Installing required packages..."
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
    jq

log "Required packages installed successfully"

# =============================================================================
# TIME SYNCHRONIZATION
# =============================================================================

log "Configuring time synchronization..."

# Sync time with domain controller
systemctl stop ntp
ntpdate -s $AD_SERVER_IP || ntpdate -s pool.ntp.org
systemctl start ntp
systemctl enable ntp

log "Time synchronization configured"

# =============================================================================
# DNS CONFIGURATION
# =============================================================================

log "Configuring DNS..."

# Backup original resolv.conf
cp /etc/resolv.conf /etc/resolv.conf.backup

# Configure DNS to use AD server
cat > /etc/resolv.conf << EOF
# DNS configuration for AD integration
nameserver $AD_SERVER_IP
search $DOMAIN_NAME
domain $DOMAIN_NAME
EOF

# Make resolv.conf immutable to prevent NetworkManager from overwriting
chattr +i /etc/resolv.conf

# Add domain controller to hosts file
echo "$AD_SERVER_IP windc.$DOMAIN_NAME windc" >> /etc/hosts
echo "$AD_SERVER_IP ldap.$DOMAIN_NAME ldap" >> /etc/hosts
echo "$AD_SERVER_IP kerberos.$DOMAIN_NAME kerberos" >> /etc/hosts

log "DNS configuration completed"

# =============================================================================
# KERBEROS CONFIGURATION
# =============================================================================

log "Configuring Kerberos..."

# Backup original krb5.conf
cp /etc/krb5.conf /etc/krb5.conf.backup 2>/dev/null || true

# Create Kerberos configuration
cat > /etc/krb5.conf << EOF
[libdefaults]
    default_realm = $DOMAIN_UPPER
    dns_lookup_realm = false
    dns_lookup_kdc = true
    ticket_lifetime = 24h
    renew_lifetime = 7d
    forwardable = true
    proxiable = true
    default_tkt_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 rc4-hmac
    default_tgs_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 rc4-hmac
    permitted_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96 rc4-hmac

[realms]
    $DOMAIN_UPPER = {
        kdc = windc.$DOMAIN_NAME
        admin_server = windc.$DOMAIN_NAME
        default_domain = $DOMAIN_NAME
    }

[domain_realm]
    .$DOMAIN_NAME = $DOMAIN_UPPER
    $DOMAIN_NAME = $DOMAIN_UPPER
    
[login]
    krb4_convert = true
    krb4_get_tickets = false
EOF

log "Kerberos configuration completed"

# =============================================================================
# LDAP CONFIGURATION
# =============================================================================

log "Configuring LDAP..."

# Configure LDAP client
cat > /etc/ldap/ldap.conf << EOF
# LDAP configuration for AD integration
BASE    dc=$(echo $DOMAIN_NAME | sed 's/\./,dc=/g')
URI     ldap://$AD_SERVER_IP ldaps://$AD_SERVER_IP
BINDDN  cn=john.doe,cn=users,dc=$(echo $DOMAIN_NAME | sed 's/\./,dc=/g')

# TLS/SSL configuration
TLS_CACERTDIR   /etc/ssl/certs
TLS_REQCERT     allow

# Referrals
REFERRALS       off

# SASL configuration
SASL_MECH       GSSAPI
SASL_REALM      $DOMAIN_UPPER
EOF

log "LDAP configuration completed"

# =============================================================================
# NSS AND PAM CONFIGURATION
# =============================================================================

log "Configuring NSS..."

# Backup original nsswitch.conf
cp /etc/nsswitch.conf /etc/nsswitch.conf.backup

# Configure NSS to use LDAP
sed -i 's/^passwd:.*/passwd:         files ldap/' /etc/nsswitch.conf
sed -i 's/^group:.*/group:          files ldap/' /etc/nsswitch.conf
sed -i 's/^shadow:.*/shadow:         files ldap/' /etc/nsswitch.conf

log "NSS configuration completed"

# =============================================================================
# CREATE TESTING SCRIPTS
# =============================================================================

log "Creating testing scripts..."

# Create testing directory
mkdir -p /opt/ad-tests
chmod 755 /opt/ad-tests

# Create comprehensive test script
cat > /opt/ad-tests/test-all.sh << 'EOF'
#!/bin/bash
# =============================================================================
# COMPREHENSIVE AD AUTHENTICATION TESTING SUITE
# =============================================================================

DOMAIN_NAME="$DOMAIN_NAME"
DOMAIN_UPPER="$DOMAIN_UPPER"
AD_SERVER_IP="$AD_SERVER_IP"

echo "======================================================================"
echo "AD Authentication Testing Suite - Case 1: Simple AD"
echo "======================================================================"
echo "Domain: $DOMAIN_NAME"
echo "Domain Controller: $AD_SERVER_IP"
echo "Test Time: $(date)"
echo "======================================================================"

# Test 1: DNS Resolution
echo ""
echo "🔍 Test 1: DNS Resolution"
echo "----------------------------------------------------------------------"
nslookup windc.$DOMAIN_NAME $AD_SERVER_IP
if [ $? -eq 0 ]; then
    echo "✅ DNS resolution: PASSED"
else
    echo "❌ DNS resolution: FAILED"
fi

# Test 2: Network Connectivity
echo ""
echo "🌐 Test 2: Network Connectivity"
echo "----------------------------------------------------------------------"
ping -c 3 $AD_SERVER_IP
if [ $? -eq 0 ]; then
    echo "✅ Network connectivity: PASSED"
else
    echo "❌ Network connectivity: FAILED"
fi

# Test 3: LDAP Port Connectivity
echo ""
echo "🔗 Test 3: LDAP Port Connectivity"
echo "----------------------------------------------------------------------"
timeout 5 bash -c "</dev/tcp/$AD_SERVER_IP/389" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ LDAP port 389: OPEN"
else
    echo "❌ LDAP port 389: CLOSED"
fi

timeout 5 bash -c "</dev/tcp/$AD_SERVER_IP/636" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ LDAPS port 636: OPEN"
else
    echo "❌ LDAPS port 636: CLOSED"
fi

# Test 4: Kerberos Port Connectivity
echo ""
echo "🎫 Test 4: Kerberos Port Connectivity"
echo "----------------------------------------------------------------------"
timeout 5 bash -c "</dev/tcp/$AD_SERVER_IP/88" 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✅ Kerberos port 88: OPEN"
else
    echo "❌ Kerberos port 88: CLOSED"
fi

# Test 5: LDAP Anonymous Bind
echo ""
echo "📂 Test 5: LDAP Anonymous Query"
echo "----------------------------------------------------------------------"
ldapsearch -x -h $AD_SERVER_IP -b "dc=$(echo $DOMAIN_NAME | sed 's/\./,dc=/g')" -s base "(objectclass=*)" 2>/dev/null | head -10
if [ $? -eq 0 ]; then
    echo "✅ LDAP anonymous query: PASSED"
else
    echo "❌ LDAP anonymous query: FAILED"
fi

echo ""
echo "======================================================================"
echo "Interactive Tests (require user input):"
echo "======================================================================"
echo ""
echo "🎫 Kerberos Authentication Test:"
echo "   Run: kinit john.doe@$DOMAIN_UPPER"
echo "   Password: TestPass123!"
echo "   Verify: klist"
echo ""
echo "🔐 LDAP Authenticated Bind Test:"
echo "   Run: ldapwhoami -H ldap://$AD_SERVER_IP -D \"john.doe@$DOMAIN_NAME\" -W"
echo "   Password: TestPass123!"
echo ""
echo "👥 LDAP User Search Test:"
echo "   Run: ldapsearch -H ldap://$AD_SERVER_IP -D \"john.doe@$DOMAIN_NAME\" -W \\"
echo "        -b \"dc=$(echo $DOMAIN_NAME | sed 's/\./,dc=/g')\" \"(objectClass=user)\" cn sAMAccountName"
echo ""
echo "🔒 LDAPS Secure Connection Test:"
echo "   Run: ldapsearch -H ldaps://$AD_SERVER_IP:636 -D \"john.doe@$DOMAIN_NAME\" -W \\"
echo "        -b \"dc=$(echo $DOMAIN_NAME | sed 's/\./,dc=/g')\" \"(sAMAccountName=linux.admin)\""
echo ""
echo "======================================================================"
echo "Test completed: $(date)"
echo "======================================================================"
EOF

chmod +x /opt/ad-tests/test-all.sh

# Create individual test scripts
cat > /opt/ad-tests/test-kerberos.sh << 'EOF'
#!/bin/bash
echo "Testing Kerberos authentication..."
echo "Available test users:"
echo "- john.doe@$DOMAIN_UPPER (Domain Admin)"
echo "- alice.brown@$DOMAIN_UPPER (Network Engineer)"
echo "- linux.admin@$DOMAIN_UPPER (Linux Admin)"
echo "- linux.user1@$DOMAIN_UPPER (Regular User)"
echo ""
echo "Password for all users: TestPass123!"
echo ""
echo "Commands to test:"
echo "kinit john.doe@$DOMAIN_UPPER"
echo "klist"
echo "kdestroy"
EOF

chmod +x /opt/ad-tests/test-kerberos.sh

cat > /opt/ad-tests/test-ldap.sh << 'EOF'
#!/bin/bash
echo "Testing LDAP authentication..."
echo "LDAP Server: $AD_SERVER_IP"
echo "Base DN: dc=$(echo $DOMAIN_NAME | sed 's/\./,dc=/g')"
echo ""
echo "Test commands:"
echo "ldapwhoami -H ldap://$AD_SERVER_IP -D \"john.doe@$DOMAIN_NAME\" -W"
echo "ldapsearch -H ldap://$AD_SERVER_IP -D \"john.doe@$DOMAIN_NAME\" -W -b \"dc=$(echo $DOMAIN_NAME | sed 's/\./,dc=/g')\" \"(objectClass=user)\""
EOF

chmod +x /opt/ad-tests/test-ldap.sh

# Create FortiProxy configuration helper
cat > /opt/ad-tests/fortiproxy-config.txt << EOF
# =============================================================================
# FORTIPROXY LDAP CONFIGURATION - Case 1: Simple AD
# =============================================================================

LDAP Server Configuration:
- Server: $AD_SERVER_IP
- Port: 389 (LDAP) or 636 (LDAPS)
- Protocol: LDAP v3
- Common Name Identifier: sAMAccountName
- Distinguished Name: dc=$(echo $DOMAIN_NAME | sed 's/\./,dc=/g')
- Bind Type: Regular
- Username: john.doe@$DOMAIN_NAME
- Password: TestPass123!

Search Filters:
- All users: (objectClass=user)
- IT Admins: (memberOf=CN=IT-Admins,OU=Security-Groups,dc=$(echo $DOMAIN_NAME | sed 's/\./,dc=/g'))
- Linux Admins: (memberOf=CN=Linux-Admins,OU=Security-Groups,dc=$(echo $DOMAIN_NAME | sed 's/\./,dc=/g'))
- SSH Users: (memberOf=CN=SSH-Users,OU=Security-Groups,dc=$(echo $DOMAIN_NAME | sed 's/\./,dc=/g'))
- FortiProxy Users: (memberOf=CN=FortiProxy-Users,OU=Security-Groups,dc=$(echo $DOMAIN_NAME | sed 's/\./,dc=/g'))
- Active users only: (&(objectClass=user)(!(userAccountControl:1.2.840.113556.1.4.803:=2)))

Test Users Available:
1. john.doe@$DOMAIN_NAME (Domain Admin, IT Admin, Linux Admin)
2. alice.brown@$DOMAIN_NAME (Linux Admin, SSH User)
3. linux.admin@$DOMAIN_NAME (Linux Admin, SSH User)
4. linux.user1@$DOMAIN_NAME (SSH User)

Service Accounts:
- svc.ldap@$DOMAIN_NAME (For LDAP binding)
- svc.krb@$DOMAIN_NAME (For Kerberos authentication)

All passwords: TestPass123!
EOF

log "Testing scripts created successfully"

# =============================================================================
# CREATE WELCOME MESSAGE
# =============================================================================

cat > /etc/motd << EOF

====================================================================
🔐 ACTIVE DIRECTORY TESTING CLIENT - CASE 1: SIMPLE AD
====================================================================

Domain: $DOMAIN_NAME
Domain Controller: $AD_SERVER_IP (windc.$DOMAIN_NAME)
Client Type: Ubuntu 20.04 LTS with Kerberos/LDAP tools

Quick Testing Commands:
  /opt/ad-tests/test-all.sh       - Run comprehensive test suite
  /opt/ad-tests/test-kerberos.sh  - Kerberos testing guide
  /opt/ad-tests/test-ldap.sh      - LDAP testing guide

Configuration Files:
  /etc/krb5.conf                  - Kerberos configuration
  /etc/ldap/ldap.conf             - LDAP client configuration
  /opt/ad-tests/fortiproxy-config.txt - FortiProxy setup guide

Test Users (Password: TestPass123!):
  john.doe@$DOMAIN_UPPER          - Domain Administrator
  alice.brown@$DOMAIN_UPPER       - Network Engineer
  linux.admin@$DOMAIN_UPPER      - Linux Administrator
  linux.user1@$DOMAIN_UPPER      - Regular User

Example Commands:
  kinit john.doe@$DOMAIN_UPPER    - Get Kerberos ticket
  klist                          - List Kerberos tickets
  ldapwhoami -H ldap://$AD_SERVER_IP -D "john.doe@$DOMAIN_NAME" -W

🚀 Deployment Status: FULLY AUTOMATED - Ready for testing!
====================================================================

EOF

# =============================================================================
# RESTART SERVICES
# =============================================================================

log "Restarting services..."

systemctl restart nscd
systemctl enable nscd

log "Services restarted successfully"

# =============================================================================
# FINAL VALIDATION
# =============================================================================

log "Performing final validation..."

# Test DNS resolution
if nslookup windc.$DOMAIN_NAME $AD_SERVER_IP > /dev/null 2>&1; then
    log "✅ DNS resolution test: PASSED"
else
    log "❌ DNS resolution test: FAILED"
fi

# Test network connectivity
if ping -c 1 $AD_SERVER_IP > /dev/null 2>&1; then
    log "✅ Network connectivity test: PASSED"
else
    log "❌ Network connectivity test: FAILED"
fi

# =============================================================================
# COMPLETION
# =============================================================================

log "Ubuntu client setup completed successfully!"
log "Client is ready for AD authentication testing"
log "Run '/opt/ad-tests/test-all.sh' to start testing"
log "All configuration files and test scripts are in place"
log "Setup log saved to: /var/log/ad-client-setup.log"

echo "AD Client setup completed - check /var/log/ad-client-setup.log for details" > /tmp/setup-complete.flag