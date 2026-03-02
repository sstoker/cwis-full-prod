#!/bin/bash
# Script to verify all production backups are working correctly
# This checks both docker-compose and codebase backups

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

echo "=========================================="
echo "  Production Backup Verification"
echo "=========================================="
echo ""

ERRORS=0
WARNINGS=0

# ============================================
# 1. Verify Docker Compose Backup
# ============================================
echo "=== 1. Docker Compose Backup ==="
cd /root/isle-dc-production

if [ -f docker-compose.yml ]; then
    print_success "docker-compose.yml exists"
    
    # Check local backup repo
    if [ -d "/root/isle-dc-production-backup" ]; then
        cd /root/isle-dc-production-backup
        
        if [ -f docker-compose.yml ]; then
            # Compare files
            if diff -q /root/isle-dc-production/docker-compose.yml docker-compose.yml >/dev/null 2>&1; then
                print_success "Local backup is up to date"
            else
                print_warning "Local backup differs from source (may need update)"
                WARNINGS=$((WARNINGS + 1))
            fi
            
            # Check Git status
            if [ -d .git ]; then
                COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo "0")
                print_success "Git repository: $COMMITS commits"
                
                # Check remote
                if git remote get-url origin >/dev/null 2>&1; then
                    REMOTE_URL=$(git remote get-url origin)
                    print_success "Remote configured: $REMOTE_URL"
                    
                    # Test remote connection
                    if git ls-remote origin >/dev/null 2>&1; then
                        print_success "Remote is accessible"
                        
                        # Check if local is ahead/behind
                        BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
                        if git fetch origin "$BRANCH" >/dev/null 2>&1; then
                            LOCAL=$(git rev-parse HEAD 2>/dev/null)
                            REMOTE=$(git rev-parse "origin/$BRANCH" 2>/dev/null || echo "")
                            if [ -n "$REMOTE" ] && [ "$LOCAL" != "$REMOTE" ]; then
                                print_warning "Local and remote are out of sync"
                                WARNINGS=$((WARNINGS + 1))
                            else
                                print_success "Local and remote are in sync"
                            fi
                        fi
                    else
                        print_error "Remote is not accessible"
                        ERRORS=$((ERRORS + 1))
                    fi
                else
                    print_warning "No remote configured (backup only local)"
                    WARNINGS=$((WARNINGS + 1))
                fi
            else
                print_error "Not a Git repository"
                ERRORS=$((ERRORS + 1))
            fi
        else
            print_error "Backup file not found"
            ERRORS=$((ERRORS + 1))
        fi
    else
        print_error "Backup repository not found"
        ERRORS=$((ERRORS + 1))
    fi
else
    print_error "Source docker-compose.yml not found"
    ERRORS=$((ERRORS + 1))
fi

echo ""

# ============================================
# 2. Verify Codebase Backup
# ============================================
echo "=== 2. Codebase Backup ==="
cd /root/isle-dc-production

if [ -d codebase ]; then
    CODEBASE_SIZE=$(du -sh codebase 2>/dev/null | cut -f1)
    print_success "Codebase directory exists ($CODEBASE_SIZE)"
    
    # Check backup repo
    if [ -d "/root/isle-dc-production-codebase-backup" ]; then
        cd /root/isle-dc-production-codebase-backup
        
        if [ -d .git ]; then
            COMMITS=$(git rev-list --count HEAD 2>/dev/null || echo "0")
            FILES=$(git ls-files 2>/dev/null | wc -l)
            BACKUP_SIZE=$(du -sh . 2>/dev/null | cut -f1)
            print_success "Git repository: $COMMITS commits, $FILES files ($BACKUP_SIZE)"
            
            # Check remote
            if git remote get-url origin >/dev/null 2>&1; then
                REMOTE_URL=$(git remote get-url origin)
                print_success "Remote configured: $REMOTE_URL"
                
                # Test remote connection
                if git ls-remote origin >/dev/null 2>&1; then
                    print_success "Remote is accessible"
                    
                    # Check sync status
                    BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
                    if git fetch origin "$BRANCH" >/dev/null 2>&1; then
                        LOCAL=$(git rev-parse HEAD 2>/dev/null)
                        REMOTE=$(git rev-parse "origin/$BRANCH" 2>/dev/null || echo "")
                        if [ -n "$REMOTE" ] && [ "$LOCAL" != "$REMOTE" ]; then
                            print_warning "Local and remote are out of sync"
                            WARNINGS=$((WARNINGS + 1))
                        else
                            print_success "Local and remote are in sync"
                        fi
                    fi
                else
                    print_error "Remote is not accessible"
                    ERRORS=$((ERRORS + 1))
                fi
            else
                print_error "No remote configured"
                ERRORS=$((ERRORS + 1))
            fi
        else
            print_error "Not a Git repository"
            ERRORS=$((ERRORS + 1))
        fi
    else
        print_error "Backup repository not found"
        ERRORS=$((ERRORS + 1))
    fi
else
    print_warning "Codebase directory not found (may be using Docker image)"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""

# ============================================
# 3. Check Cron Jobs
# ============================================
echo "=== 3. Automated Backups (Cron) ==="
CRON_OUTPUT=$(crontab -l 2>/dev/null | grep -v "^#" | grep -E "backup|monitor-backups" || true)
if [ -n "$CRON_OUTPUT" ]; then
    CRON_COUNT=$(echo "$CRON_OUTPUT" | wc -l)
    print_success "$CRON_COUNT backup cron job(s) configured"
    echo "$CRON_OUTPUT" | while IFS= read -r line; do
        [ -n "$line" ] && echo "  $line"
    done
else
    print_warning "No backup cron jobs found"
    WARNINGS=$((WARNINGS + 1))
fi

echo ""

# ============================================
# Summary
# ============================================
echo "=========================================="
echo "  Verification Summary"
echo "=========================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    print_success "All backups are healthy!"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    print_warning "Backups are working but have $WARNINGS warning(s)"
    exit 0
else
    print_error "Backup verification found $ERRORS error(s) and $WARNINGS warning(s)"
    exit 1
fi
