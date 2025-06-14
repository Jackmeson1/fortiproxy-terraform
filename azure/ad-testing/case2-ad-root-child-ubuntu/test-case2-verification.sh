#!/bin/bash
# =============================================================================
# CASE 2 VERIFICATION: Multi-Domain Kerberos Ticket Acquisition
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

echo ""
echo "======================================================================"
echo "🎫 CASE 2 VERIFICATION: Multi-Domain Kerberos Testing"
echo "======================================================================"
echo ""

# Configuration
ROOT_DOMAIN="corp.local"
CHILD_DOMAIN="dev.corp.local"
ROOT_DOMAIN_UPPER="CORP.LOCAL"
CHILD_DOMAIN_UPPER="DEV.CORP.LOCAL"
ROOT_DC_IP="10.0.1.4"
CHILD_DC_IP="10.0.2.4"

# =============================================================================
# PHASE 1: NETWORK CONNECTIVITY VERIFICATION
# =============================================================================

log "🌐 Phase 1: Network Connectivity Verification"

# Test DNS resolution
log "Testing DNS resolution..."
if nslookup rootdc.$ROOT_DOMAIN $ROOT_DC_IP >/dev/null 2>&1; then
    success "Root domain DNS resolution working"
else
    error "Root domain DNS resolution failed"
    exit 1
fi

if nslookup childdc.$CHILD_DOMAIN $CHILD_DC_IP >/dev/null 2>&1; then
    success "Child domain DNS resolution working"
else
    error "Child domain DNS resolution failed"
    exit 1
fi

# Test port connectivity
log "Testing service port connectivity..."
for port in 88 389 636 53; do
    if timeout 5 bash -c "</dev/tcp/$ROOT_DC_IP/$port" 2>/dev/null; then
        success "Root DC port $port accessible"
    else
        warning "Root DC port $port not accessible"
    fi
done

for port in 88 389 636; do
    if timeout 5 bash -c "</dev/tcp/$CHILD_DC_IP/$port" 2>/dev/null; then
        success "Child DC port $port accessible"
    else
        warning "Child DC port $port not accessible"
    fi
done

# Test Global Catalog
if timeout 5 bash -c "</dev/tcp/$ROOT_DC_IP/3268" 2>/dev/null; then
    success "Global Catalog port 3268 accessible"
else
    warning "Global Catalog port 3268 not accessible"
fi

# =============================================================================
# PHASE 2: KERBEROS CONFIGURATION VERIFICATION
# =============================================================================

log "🎫 Phase 2: Kerberos Configuration Verification"

# Check krb5.conf
if [ -f /etc/krb5.conf ]; then
    success "Kerberos configuration file exists"
    
    if grep -q "$ROOT_DOMAIN_UPPER" /etc/krb5.conf; then
        success "Root domain realm configured in krb5.conf"
    else
        error "Root domain realm not found in krb5.conf"
    fi
    
    if grep -q "$CHILD_DOMAIN_UPPER" /etc/krb5.conf; then
        success "Child domain realm configured in krb5.conf"
    else
        error "Child domain realm not found in krb5.conf"
    fi
else
    error "Kerberos configuration file not found"
    exit 1
fi

# =============================================================================
# PHASE 3: LDAP CONNECTIVITY TESTING
# =============================================================================

log "📂 Phase 3: LDAP Connectivity Testing"

# Test anonymous LDAP queries
log "Testing anonymous LDAP queries..."

if ldapsearch -x -h $ROOT_DC_IP -b "DC=corp,DC=local" -s base "(objectclass=*)" >/dev/null 2>&1; then
    success "Root domain LDAP anonymous query successful"
else
    warning "Root domain LDAP anonymous query failed"
fi

if ldapsearch -x -h $CHILD_DC_IP -b "DC=dev,DC=corp,DC=local" -s base "(objectclass=*)" >/dev/null 2>&1; then
    success "Child domain LDAP anonymous query successful"
else
    warning "Child domain LDAP anonymous query failed"
fi

# Test Global Catalog
if ldapsearch -x -h $ROOT_DC_IP -p 3268 -b "DC=corp,DC=local" -s base "(objectclass=*)" >/dev/null 2>&1; then
    success "Global Catalog LDAP query successful"
else
    warning "Global Catalog LDAP query failed"
fi

# =============================================================================
# PHASE 4: KERBEROS TICKET ACQUISITION (THE MAIN CHALLENGE)
# =============================================================================

log "🎯 Phase 4: Kerberos Ticket Acquisition Challenge"

# Clear any existing tickets
kdestroy >/dev/null 2>&1 || true

echo ""
log "🏢 Testing ROOT DOMAIN ticket acquisition..."

# Test root domain ticket acquisition
echo "Testing enterprise.admin@$ROOT_DOMAIN_UPPER ticket acquisition..."
echo "TestPass123!" | kinit enterprise.admin@$ROOT_DOMAIN_UPPER >/dev/null 2>&1

if [ $? -eq 0 ]; then
    success "ROOT DOMAIN ticket acquisition successful!"
    
    # Verify ticket
    klist | grep "enterprise.admin@$ROOT_DOMAIN_UPPER" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        success "ROOT DOMAIN ticket verified in cache"
        echo "$(klist | grep 'Default principal\|enterprise.admin')"
    fi
else
    error "ROOT DOMAIN ticket acquisition FAILED"
fi

# Clear tickets
kdestroy >/dev/null 2>&1 || true

echo ""
log "🏗️ Testing CHILD DOMAIN ticket acquisition..."

# Test child domain ticket acquisition  
echo "Testing dev.lead@$CHILD_DOMAIN_UPPER ticket acquisition..."
echo "TestPass123!" | kinit dev.lead@$CHILD_DOMAIN_UPPER >/dev/null 2>&1

if [ $? -eq 0 ]; then
    success "CHILD DOMAIN ticket acquisition successful!"
    
    # Verify ticket
    klist | grep "dev.lead@$CHILD_DOMAIN_UPPER" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        success "CHILD DOMAIN ticket verified in cache"
        echo "$(klist | grep 'Default principal\|dev.lead')"
    fi
else
    error "CHILD DOMAIN ticket acquisition FAILED"
fi

# =============================================================================
# PHASE 5: CROSS-DOMAIN AUTHENTICATION TESTING
# =============================================================================

log "🔗 Phase 5: Cross-Domain Authentication Testing"

# Clear tickets and get root domain ticket
kdestroy >/dev/null 2>&1 || true
echo "TestPass123!" | kinit enterprise.admin@$ROOT_DOMAIN_UPPER >/dev/null 2>&1

if [ $? -eq 0 ]; then
    log "Testing cross-domain LDAP query with root domain ticket..."
    
    # Try to query child domain using root domain credentials
    if ldapsearch -H ldap://$CHILD_DC_IP -Y GSSAPI -b "DC=dev,DC=corp,DC=local" "(objectClass=user)" cn >/dev/null 2>&1; then
        success "Cross-domain LDAP query successful (root → child)"
    else
        warning "Cross-domain LDAP query failed (root → child)"
    fi
fi

# Test reverse: child domain ticket accessing root domain
kdestroy >/dev/null 2>&1 || true
echo "TestPass123!" | kinit dev.lead@$CHILD_DOMAIN_UPPER >/dev/null 2>&1

if [ $? -eq 0 ]; then
    log "Testing cross-domain LDAP query with child domain ticket..."
    
    # Try to query root domain using child domain credentials
    if ldapsearch -H ldap://$ROOT_DC_IP -Y GSSAPI -b "DC=corp,DC=local" "(objectClass=user)" cn >/dev/null 2>&1; then
        success "Cross-domain LDAP query successful (child → root)"
    else
        warning "Cross-domain LDAP query failed (child → root)"
    fi
fi

# =============================================================================
# PHASE 6: TRUST RELATIONSHIP VERIFICATION
# =============================================================================

log "🤝 Phase 6: Trust Relationship Verification"

# Get a ticket and check trusted realms
echo "TestPass123!" | kinit enterprise.admin@$ROOT_DOMAIN_UPPER >/dev/null 2>&1

log "Checking trusted Kerberos realms..."
if klist -T 2>/dev/null | grep -E "$ROOT_DOMAIN_UPPER|$CHILD_DOMAIN_UPPER" >/dev/null; then
    success "Trust relationship visible in Kerberos"
    echo "Trusted realms:"
    klist -T 2>/dev/null | grep -E "$ROOT_DOMAIN_UPPER|$CHILD_DOMAIN_UPPER" || echo "  (Trust details not available)"
else
    warning "Trust relationship not visible in Kerberos client"
fi

# =============================================================================
# PHASE 7: AUTHENTICATED LDAP TESTING
# =============================================================================

log "🔐 Phase 7: Authenticated LDAP Testing"

# Clear tickets and test authenticated LDAP with different domain users
kdestroy >/dev/null 2>&1 || true

# Test root domain authenticated LDAP
log "Testing authenticated LDAP with root domain credentials..."
if ldapwhoami -H ldap://$ROOT_DC_IP -D "enterprise.admin@$ROOT_DOMAIN" -w "TestPass123!" >/dev/null 2>&1; then
    success "Root domain authenticated LDAP successful"
else
    warning "Root domain authenticated LDAP failed"
fi

# Test child domain authenticated LDAP
log "Testing authenticated LDAP with child domain credentials..."
if ldapwhoami -H ldap://$CHILD_DC_IP -D "dev.lead@$CHILD_DOMAIN" -w "TestPass123!" >/dev/null 2>&1; then
    success "Child domain authenticated LDAP successful"
else
    warning "Child domain authenticated LDAP failed"
fi

# Test Global Catalog with enterprise admin
log "Testing Global Catalog with enterprise credentials..."
if ldapwhoami -H ldap://$ROOT_DC_IP:3268 -D "enterprise.admin@$ROOT_DOMAIN" -w "TestPass123!" >/dev/null 2>&1; then
    success "Global Catalog authenticated access successful"
else
    warning "Global Catalog authenticated access failed"
fi

# =============================================================================
# FINAL RESULTS
# =============================================================================

echo ""
echo "======================================================================"
echo "🏆 CASE 2 VERIFICATION RESULTS"
echo "======================================================================"
echo ""

# Count successful tests
TESTS_PASSED=0
TESTS_TOTAL=12

# Check critical success criteria
if command -v kinit >/dev/null && command -v klist >/dev/null; then
    success "Kerberos tools available"
    ((TESTS_PASSED++))
fi

if [ -f /etc/krb5.conf ] && grep -q "$ROOT_DOMAIN_UPPER" /etc/krb5.conf; then
    success "Multi-domain Kerberos configuration"
    ((TESTS_PASSED++))
fi

if timeout 5 bash -c "</dev/tcp/$ROOT_DC_IP/88" 2>/dev/null; then
    success "Root domain Kerberos connectivity"
    ((TESTS_PASSED++))
fi

if timeout 5 bash -c "</dev/tcp/$CHILD_DC_IP/88" 2>/dev/null; then
    success "Child domain Kerberos connectivity"
    ((TESTS_PASSED++))
fi

# Main challenge tests would be performed here
echo ""
echo "🎯 CRITICAL CHALLENGE TESTS:"
echo "  📋 Root domain ticket acquisition: [Test in real deployment]"
echo "  📋 Child domain ticket acquisition: [Test in real deployment]"
echo "  📋 Cross-domain authentication: [Test in real deployment]"
echo "  📋 Trust relationship verification: [Test in real deployment]"
echo ""

echo "🎉 Verification framework ready for real deployment testing!"
echo "Run this script on deployed Ubuntu client to verify multi-domain functionality."
echo ""

# Cleanup
kdestroy >/dev/null 2>&1 || true

