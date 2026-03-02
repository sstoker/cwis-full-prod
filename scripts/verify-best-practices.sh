#!/bin/bash
# Best Practices Verification Script for Islandora at library.cwis.org
# This script verifies that all security and configuration best practices are met

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

echo "=== Islandora Best Practices Verification ==="
echo ""

ERRORS=0
WARNINGS=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# 1. Verify settings.php security
echo "1. Settings.php Security:"
PERMS=$(docker compose exec -T drupal stat -c "%a" /var/www/drupal/web/sites/default/settings.php 2>/dev/null | tr -d '\r\n' || echo "000")
if [ "$PERMS" = "400" ] || [ "$PERMS" = "444" ]; then
    check_pass "settings.php is read-only (perms: $PERMS)"
else
    check_fail "settings.php is writable (perms: $PERMS, security risk)"
fi

PASSWORD_COUNT=$(docker compose exec -T drupal grep -c "password" /var/www/drupal/web/sites/default/settings.php 2>/dev/null || echo "0")
if [ "$PASSWORD_COUNT" -eq "1" ]; then
    check_pass "Only one password line in settings.php"
else
    check_fail "Multiple password lines found in settings.php ($PASSWORD_COUNT)"
fi

HARDCODED=$(docker compose exec -T drupal grep -E "password.*=.*'password'" /var/www/drupal/web/sites/default/settings.php 2>/dev/null | wc -l)
if [ "$HARDCODED" -eq "0" ]; then
    check_pass "No hardcoded 'password' values found"
else
    check_fail "Hardcoded 'password' values found ($HARDCODED)"
fi

PASSWORD_LENGTH=$(docker compose exec -T drupal php -r "include '/var/www/drupal/web/sites/default/settings.php'; echo strlen(\$databases['default']['default']['password']);" 2>/dev/null || echo "0")
if [ "$PASSWORD_LENGTH" -eq "48" ]; then
    check_pass "Password uses secret file (48 chars)"
else
    check_fail "Password length incorrect ($PASSWORD_LENGTH chars, expected 48)"
fi

# 2. Verify Drupal configuration
echo ""
echo "2. Drupal Configuration:"
HASH_SALT=$(docker compose exec -T drupal php -r "include '/var/www/drupal/web/sites/default/settings.php'; echo isset(\$settings['hash_salt']) && strlen(\$settings['hash_salt']) > 40 ? '1' : '0';" 2>/dev/null || echo "0")
if [ "$HASH_SALT" -eq "1" ]; then
    check_pass "Hash salt is set and secure"
else
    check_fail "Hash salt not set or too short"
fi

REVERSE_PROXY=$(docker compose exec -T drupal php -r "include '/var/www/drupal/web/sites/default/settings.php'; echo isset(\$settings['reverse_proxy']) && \$settings['reverse_proxy'] ? '1' : '0';" 2>/dev/null || echo "0")
if [ "$REVERSE_PROXY" -eq "1" ]; then
    check_pass "Reverse proxy is enabled"
else
    check_warn "Reverse proxy not enabled"
fi

CONFIG_SYNC=$(docker compose exec -T drupal php -r "include '/var/www/drupal/web/sites/default/settings.php'; echo isset(\$settings['config_sync_directory']) ? '1' : '0';" 2>/dev/null || echo "0")
if [ "$CONFIG_SYNC" -eq "1" ]; then
    check_pass "Config sync directory is set"
else
    check_warn "Config sync directory not set"
fi

# 3. Verify database connection
echo ""
echo "3. Database Connection:"
DB_STATUS=$(docker compose exec -T drupal drush status 2>&1 | grep "Database" | grep -c "Connected" || echo "0")
if [ "$DB_STATUS" -eq "1" ]; then
    check_pass "Database is connected"
else
    check_fail "Database connection failed"
fi

DB_TEST=$(docker compose exec -T drupal drush sqlq "SELECT 1" 2>&1 | grep -c "1" || echo "0")
if [ "$DB_TEST" -eq "1" ]; then
    check_pass "Database queries working"
else
    check_fail "Database queries failing"
fi

# 4. Verify SSL/TLS
echo ""
echo "4. SSL/TLS Configuration:"
SSL_SUBJECT=$(openssl s_client -connect library.cwis.org:443 -servername library.cwis.org </dev/null 2>/dev/null | openssl x509 -noout -subject 2>/dev/null | grep -c "library.cwis.org" || echo "0")
if [ "$SSL_SUBJECT" -gt "0" ]; then
    check_pass "SSL certificate is valid for library.cwis.org"
else
    check_fail "SSL certificate invalid or missing"
fi

SSL_ISSUER=$(openssl s_client -connect library.cwis.org:443 -servername library.cwis.org </dev/null 2>/dev/null | openssl x509 -noout -issuer 2>/dev/null | grep -c "Let's Encrypt" || echo "0")
if [ "$SSL_ISSUER" -gt "0" ]; then
    check_pass "SSL certificate from Let's Encrypt"
else
    check_warn "SSL certificate not from Let's Encrypt"
fi

SSL_EXPIRY=$(openssl s_client -connect library.cwis.org:443 -servername library.cwis.org </dev/null 2>/dev/null | openssl x509 -noout -dates 2>/dev/null | grep "notAfter" | cut -d= -f2)
if [ -n "$SSL_EXPIRY" ]; then
    EXPIRY_EPOCH=$(date -d "$SSL_EXPIRY" +%s 2>/dev/null || echo "0")
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))
    if [ "$DAYS_LEFT" -gt "30" ]; then
        check_pass "SSL certificate valid for $DAYS_LEFT more days"
    elif [ "$DAYS_LEFT" -gt "0" ]; then
        check_warn "SSL certificate expires in $DAYS_LEFT days"
    else
        check_fail "SSL certificate has expired"
    fi
fi

# 5. Verify Docker secrets
echo ""
echo "5. Docker Secrets:"
SECRET_EXISTS=$(docker compose exec -T drupal test -f /run/secrets/DRUPAL_DEFAULT_DB_PASSWORD && echo "1" || echo "0")
if [ "$SECRET_EXISTS" -eq "1" ]; then
    check_pass "Database password secret file exists"
else
    check_fail "Database password secret file missing"
fi

SECRET_READABLE=$(docker compose exec -T drupal test -r /run/secrets/DRUPAL_DEFAULT_DB_PASSWORD && echo "1" || echo "0")
if [ "$SECRET_READABLE" -eq "1" ]; then
    check_pass "Secret file is readable"
else
    check_fail "Secret file not readable"
fi

# 6. Verify init script
echo ""
echo "6. Init Script Configuration:"
INIT_SCRIPT=$(docker compose exec -T drupal test -f /etc/cont-init.d/05-fix-db-password.sh && echo "1" || echo "0")
if [ "$INIT_SCRIPT" -eq "1" ]; then
    check_pass "Custom init script is mounted"
else
    check_fail "Custom init script not found"
fi

# 7. Verify site accessibility
echo ""
echo "7. Site Accessibility:"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://library.cwis.org --max-time 5 || echo "000")
if [ "$HTTP_STATUS" -eq "200" ]; then
    check_pass "Site returns HTTP 200"
elif [ "$HTTP_STATUS" -eq "404" ]; then
    check_warn "Site returns HTTP 404 (may be starting up)"
else
    check_fail "Site returns HTTP $HTTP_STATUS"
fi

# Summary
echo ""
echo "=== Summary ==="
if [ "$ERRORS" -eq "0" ] && [ "$WARNINGS" -eq "0" ]; then
    echo -e "${GREEN}All checks passed!${NC}"
    exit 0
elif [ "$ERRORS" -eq "0" ]; then
    echo -e "${YELLOW}$WARNINGS warning(s) found${NC}"
    exit 0
else
    echo -e "${RED}$ERRORS error(s) and $WARNINGS warning(s) found${NC}"
    exit 1
fi
