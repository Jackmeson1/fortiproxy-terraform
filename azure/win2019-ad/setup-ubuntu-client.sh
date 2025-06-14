#!/bin/bash
# Ubuntu Client Setup Script for AD Authentication

# Variables passed from Terraform
DOMAIN_NAME="${domain_name}"
DOMAIN_UPPER="${domain_upper}"
NETBIOS_NAME="${netbios_name}"
DC_IP="$${dc_ip}"
ADMIN_USERNAME="${admin_username}"
ADMIN_PASSWORD="${admin_password}"

# Update system
apt-get update -y
apt-get upgrade -y

# Install required packages
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    realmd \
    sssd \
    sssd-tools \
    libnss-sss \
    libpam-sss \
    adcli \
    samba-common-bin \
    oddjob \
    oddjob-mkhomedir \
    packagekit \
    krb5-user \
    ldap-utils \
    python3-pip \
    ntp

# Configure NTP to sync with DC
cat > /etc/ntp.conf << EOF
driftfile /var/lib/ntp/ntp.drift
statistics loopstats peerstats clockstats
filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable

server $DC_IP iburst prefer
server 0.ubuntu.pool.ntp.org iburst
server 1.ubuntu.pool.ntp.org iburst

restrict -4 default kod notrap nomodify nopeer noquery limited
restrict -6 default kod notrap nomodify nopeer noquery limited
restrict 127.0.0.1
restrict ::1
restrict source notrap nomodify noquery
EOF

systemctl restart ntp
sleep 5

# Configure Kerberos
cat > /etc/krb5.conf << EOF
[libdefaults]
    default_realm = $DOMAIN_UPPER
    dns_lookup_realm = false
    dns_lookup_kdc = true
    rdns = false
    ticket_lifetime = 24h
    forwardable = true
    default_ccache_name = KEYRING:persistent:%%{uid}
    default_tgs_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96
    default_tkt_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96
    permitted_enctypes = aes256-cts-hmac-sha1-96 aes128-cts-hmac-sha1-96

[realms]
    $DOMAIN_UPPER = {
        kdc = windc2019.$DOMAIN_NAME
        admin_server = windc2019.$DOMAIN_NAME
        default_domain = $DOMAIN_NAME
    }

[domain_realm]
    .$DOMAIN_NAME = $DOMAIN_UPPER
    $DOMAIN_NAME = $DOMAIN_UPPER

[logging]
    default = FILE:/var/log/krb5libs.log
    kdc = FILE:/var/log/krb5kdc.log
    admin_server = FILE:/var/log/kadmind.log
EOF

# Configure /etc/hosts
echo "$DC_IP windc2019.$DOMAIN_NAME windc2019" >> /etc/hosts

# Configure DNS
cat > /etc/resolv.conf << EOF
nameserver $DC_IP
search $DOMAIN_NAME
EOF

# Make resolv.conf immutable to prevent overwrite
chattr +i /etc/resolv.conf

# Test DNS resolution
sleep 5
nslookup windc2019.$DOMAIN_NAME

# Initialize Kerberos ticket for admin
echo "$ADMIN_PASSWORD" | kinit "$ADMIN_USERNAME@$DOMAIN_UPPER"

# Join the domain using realm
echo "$ADMIN_PASSWORD" | realm join --verbose --user="$ADMIN_USERNAME" "$DOMAIN_NAME" --os-name="Ubuntu" --os-version="20.04"

# Configure SSSD
cat > /etc/sssd/sssd.conf << EOF
[sssd]
domains = $DOMAIN_NAME
config_file_version = 2
services = nss, pam, ssh, sudo

[domain/$DOMAIN_NAME]
ad_domain = $DOMAIN_NAME
krb5_realm = $DOMAIN_UPPER
realmd_tags = manages-system joined-with-adcli
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = True
use_fully_qualified_names = False
fallback_homedir = /home/%u
access_provider = ad
ad_gpo_access_control = permissive
dyndns_update = true
dyndns_refresh_interval = 43200
dyndns_update_ptr = true
dyndns_ttl = 3600

# Performance tuning
ldap_schema = ad
ldap_idmap_range_min = 100000
ldap_idmap_range_max = 2000100000
ldap_idmap_range_size = 2000000000
ldap_referrals = false
ldap_page_size = 1000
ldap_enumeration_refresh_timeout = 300

# Authentication settings
auth_provider = ad
chpass_provider = ad
ldap_sasl_mech = GSSAPI
ldap_sasl_authid = host/$$(hostname -f)
krb5_keytab = /etc/krb5.keytab
ldap_krb5_keytab = /etc/krb5.keytab
krb5_use_enterprise_principal = True

[nss]
filter_groups = root
filter_users = root
reconnection_retries = 3
entry_cache_timeout = 3600
entry_cache_user_timeout = 3600
entry_cache_group_timeout = 3600
entry_cache_sudo_timeout = 3600

[pam]
reconnection_retries = 3
offline_credentials_expiration = 7
offline_failed_login_attempts = 3
offline_failed_login_delay = 5

[sudo]
sudo_cache_timeout = 3600

[ssh]
ssh_hash_known_hosts = True
EOF

# Set correct permissions
chmod 600 /etc/sssd/sssd.conf

# Configure PAM for mkhomedir
pam-auth-update --enable mkhomedir

# Configure sudo for domain admins
cat >> /etc/sudoers.d/domain_admins << EOF
# Allow domain admins sudo access
%domain\ admins ALL=(ALL:ALL) ALL
%linux-admins ALL=(ALL:ALL) ALL
%it-admins ALL=(ALL:ALL) ALL
EOF

# Configure SSH to allow password authentication for testing
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Add SSH access for domain groups
cat >> /etc/ssh/sshd_config << EOF

# Allow SSH access for domain groups
AllowGroups ssh-users linux-admins domain\ admins
EOF

# Restart services
systemctl restart sssd
systemctl restart ssh
systemctl enable sssd

# Create test scripts directory
mkdir -p /opt/ad-tests

# Create Kerberos test script
cat > /opt/ad-tests/test-kerberos.sh << 'EOF'
#!/bin/bash
echo "=== Kerberos Authentication Test ==="
echo ""

# Test users array
TEST_USERS=("john.doe" "alice.brown" "linux.admin" "linux.user1")

for user in "$${TEST_USERS[@]}"; do
    echo "Testing Kerberos authentication for $user:"
    echo -n "Enter password for $user: "
    read -s password
    echo ""
    
    # Get Kerberos ticket
    echo "$password" | kinit "$user@EXAMPLE.COM" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully obtained Kerberos ticket for $user"
        echo "Ticket details:"
        klist
        kdestroy
    else
        echo "✗ Failed to obtain Kerberos ticket for $user"
    fi
    echo "---"
done
EOF

# Create LDAP test script
cat > /opt/ad-tests/test-ldap.sh << 'EOF'
#!/bin/bash
echo "=== LDAP Authentication Test ==="
echo ""

DC_IP="$${dc_ip}"
BASE_DN="DC=example,DC=com"

# Test LDAP bind with different users
TEST_USERS=("john.doe" "jane.smith" "linux.admin" "svc.ldap")

for user in "$${TEST_USERS[@]}"; do
    echo "Testing LDAP bind for $user:"
    echo -n "Enter password for $user: "
    read -s password
    echo ""
    
    # Test LDAP bind
    ldapwhoami -H ldap://$DC_IP -D "$user@example.com" -w "$password" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✓ LDAP bind successful for $user"
        
        # Search for user details
        echo "User details:"
        ldapsearch -H ldap://$DC_IP -D "$user@example.com" -w "$password" \
            -b "$BASE_DN" "(sAMAccountName=$user)" cn mail memberOf 2>/dev/null | \
            grep -E "^(cn:|mail:|memberOf:)" | head -10
    else
        echo "✗ LDAP bind failed for $user"
    fi
    echo "---"
done

# Anonymous LDAP query test
echo "Testing anonymous LDAP query (should fail):"
ldapsearch -H ldap://$DC_IP -x -b "$BASE_DN" "(objectClass=user)" cn 2>&1 | head -5
EOF

# Create keytab generation script
cat > /opt/ad-tests/create-keytab.sh << 'EOF'
#!/bin/bash
echo "=== Service Keytab Creation ==="
echo ""

SERVICE_USER="svc.krb"
HOSTNAME=$$(hostname -f)

echo "Creating keytab for host service"
echo -n "Enter password for $SERVICE_USER: "
read -s password
echo ""

# Create keytab
echo "$password" | kinit "$SERVICE_USER@EXAMPLE.COM"

if [ $? -eq 0 ]; then
    # Create keytab
    kvno host/$HOSTNAME@EXAMPLE.COM
    
    # Add to keytab
    echo "$password" | ktutil << END
addent -password -p host/$HOSTNAME@EXAMPLE.COM -k 1 -e aes256-cts-hmac-sha1-96
wkt /etc/krb5.keytab
quit
END
    
    echo "Keytab created. Contents:"
    klist -kte /etc/krb5.keytab
    
    kdestroy
else
    echo "Failed to authenticate as service account"
fi
EOF

# Create comprehensive test script
cat > /opt/ad-tests/test-all.sh << 'EOF'
#!/bin/bash
echo "=== Comprehensive AD Integration Test ==="
echo ""
echo "DC IP: $${dc_ip}"
echo "Domain: example.com"
echo "Realm: EXAMPLE.COM"
echo ""

# 1. DNS Test
echo "1. DNS Resolution Test:"
nslookup windc2019.example.com
echo ""

# 2. Kerberos Test
echo "2. Kerberos Connectivity Test:"
echo "" | kinit -V john.doe@EXAMPLE.COM 2>&1 | head -5
echo ""

# 3. LDAP Test
echo "3. LDAP Connectivity Test:"
ldapsearch -H ldap://windc2019.example.com -x -s base -b "" "objectClass=*" namingContexts 2>&1 | head -10
echo ""

# 4. SSSD Status
echo "4. SSSD Service Status:"
systemctl status sssd --no-pager | head -10
echo ""

# 5. AD Users enumeration
echo "5. AD Users visible to system:"
getent passwd | grep -E "(john|jane|alice|bob|linux)" | head -10
echo ""

# 6. AD Groups enumeration
echo "6. AD Groups visible to system:"
getent group | grep -i -E "(admin|users|ssh)" | head -10
echo ""

# 7. Authentication test
echo "7. PAM Authentication Test:"
echo "Run: su - john.doe"
echo "(This will test if AD users can log in)"
echo ""

# 8. Realm status
echo "8. Realm Status:"
realm list
echo ""

echo "=== Test Complete ==="
echo "For detailed tests, run:"
echo "  - /opt/ad-tests/test-kerberos.sh"
echo "  - /opt/ad-tests/test-ldap.sh"
echo "  - /opt/ad-tests/create-keytab.sh"
EOF

# Make scripts executable
chmod +x /opt/ad-tests/*.sh

# Wait for services to stabilize
sleep 10

# Final check
echo "=== Setup Complete ==="
echo "Domain joined successfully. Testing configuration..."
realm list

# Create README
cat > /opt/ad-tests/README.md << EOF
# AD Authentication Test Suite

This Ubuntu client is configured to authenticate against Windows Server 2019 AD.

## Configuration
- Domain: example.com
- DC: windc2019.example.com ($DC_IP)
- Kerberos Realm: EXAMPLE.COM

## Test Users
- john.doe (IT Admin)
- alice.brown (Network Engineer)
- linux.admin (Linux Administrator)
- linux.user1 (Regular Linux User)

## Available Tests
1. **/opt/ad-tests/test-all.sh** - Comprehensive connectivity test
2. **/opt/ad-tests/test-kerberos.sh** - Interactive Kerberos authentication
3. **/opt/ad-tests/test-ldap.sh** - LDAP bind and search tests
4. **/opt/ad-tests/create-keytab.sh** - Create service keytab

## Quick Commands
- Get Kerberos ticket: \`kinit username@EXAMPLE.COM\`
- List tickets: \`klist\`
- Destroy tickets: \`kdestroy\`
- LDAP search: \`ldapsearch -H ldap://$DC_IP -D "user@example.com" -W -b "DC=example,DC=com"\`
- Check user: \`id username\`
- Switch user: \`su - username\`

## SSH Access
SSH is configured to allow password authentication for testing.
Domain users in 'ssh-users' or 'linux-admins' groups can SSH to this system.
EOF

echo "Setup complete! Check /opt/ad-tests/README.md for usage instructions."