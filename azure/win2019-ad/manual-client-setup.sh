#!/bin/bash
# Manual Ubuntu Client Setup for AD Authentication
# Run this on the Ubuntu client after AD server is configured

DC_IP="10.0.1.4"
DOMAIN_NAME="example.com"
DOMAIN_UPPER="EXAMPLE.COM"

echo "=== Ubuntu Client AD Setup ==="
echo "DC IP: $DC_IP"
echo "Domain: $DOMAIN_NAME"
echo "Realm: $DOMAIN_UPPER"
echo ""

# Update system
sudo apt-get update -y

# Install required packages
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
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

# Configure /etc/hosts
echo "Configuring /etc/hosts..."
echo "$DC_IP windc2019.$DOMAIN_NAME windc2019" | sudo tee -a /etc/hosts

# Configure DNS
echo "Configuring DNS..."
sudo bash -c "cat > /etc/resolv.conf << EOF
nameserver $DC_IP
search $DOMAIN_NAME
EOF"

# Make resolv.conf immutable to prevent overwrite
sudo chattr +i /etc/resolv.conf

# Configure Kerberos
echo "Configuring Kerberos..."
sudo bash -c "cat > /etc/krb5.conf << EOF
[libdefaults]
    default_realm = $DOMAIN_UPPER
    dns_lookup_realm = false
    dns_lookup_kdc = true
    rdns = false
    ticket_lifetime = 24h
    forwardable = true
    default_ccache_name = KEYRING:persistent:%{uid}
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
EOF"

# Test DNS resolution
echo "Testing DNS resolution..."
nslookup windc2019.$DOMAIN_NAME

echo ""
echo "=== Manual Steps Required ==="
echo "1. Test Kerberos authentication:"
echo "   kinit john.doe@$DOMAIN_UPPER"
echo "   (password: TestPass123!)"
echo ""
echo "2. Join domain (run as root):"
echo "   realm join --verbose --user=azureuser $DOMAIN_NAME"
echo ""
echo "3. Test LDAP connectivity:"
echo "   ldapsearch -H ldap://$DC_IP -D \"john.doe@$DOMAIN_NAME\" -W -b \"DC=example,DC=com\""
echo ""
echo "Setup script complete. Follow manual steps above."