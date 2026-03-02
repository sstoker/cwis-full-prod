#!/bin/bash
# Script to backup production codebase to a separate git repository
# This creates a private backup repository structure for the Drupal codebase

set -e

cd /root/isle-dc-production

BACKUP_REPO_DIR="/root/isle-dc-production-codebase-backup"
BACKUP_REPO_REMOTE="${CODEBASE_BACKUP_REMOTE:-}"  # Set this environment variable if you have a remote

echo "=== Production Codebase Git Backup ==="
echo ""

# Check if codebase directory exists
if [ ! -d "codebase" ]; then
    echo "Error: codebase directory not found!"
    echo "Location: /root/isle-dc-production/codebase"
    exit 1
fi

# Initialize backup repository if it doesn't exist
if [ ! -d "$BACKUP_REPO_DIR" ]; then
    echo "Creating codebase backup repository at $BACKUP_REPO_DIR..."
    mkdir -p "$BACKUP_REPO_DIR"
    cd "$BACKUP_REPO_DIR"
    git init
    
    # Create .gitignore for the backup repo (exclude common build artifacts)
    cat > .gitignore << 'EOF'
# Build artifacts
/vendor/
/node_modules/
/.git/
/.idea/
/.vscode/

# Drupal specific
/sites/default/files/
/sites/default/settings.php
/sites/default/settings.local.php
*.log

# Temporary files
*.tmp
*.bak
*~
.DS_Store
EOF
    
    git add .gitignore
    git commit -m "Initial commit: Production codebase backup repository"
    cd - > /dev/null
    echo "✓ Backup repository initialized"
fi

# Copy codebase to backup repo using rsync to preserve structure and exclude ignored files
echo "Copying codebase to backup repository..."
cd "$BACKUP_REPO_DIR"

# Use rsync to copy, excluding vendor and other large directories that can be regenerated
rsync -av --delete \
    --exclude='vendor/' \
    --exclude='node_modules/' \
    --exclude='sites/default/files/' \
    --exclude='.git/' \
    --exclude='.idea/' \
    --exclude='.vscode/' \
    --exclude='*.log' \
    --exclude='*.tmp' \
    --exclude='*.bak' \
    --exclude='.DS_Store' \
    /root/isle-dc-production/codebase/ ./

# Check if there are any changes to commit
if ! git diff --quiet 2>/dev/null || [ -n "$(git ls-files --others --exclude-standard)" ]; then
    echo "Staging changes..."
    git add -A
    
    # Count files for commit message
    FILE_COUNT=$(git diff --cached --numstat | wc -l)
    echo "Committing $FILE_COUNT file(s)..."
    
    git commit -m "Backup: Production codebase $(date +%Y-%m-%d\ %H:%M:%S)" || {
        echo "  (No changes to commit - codebase is up to date)"
        exit 0
    }
    echo "✓ Changes committed to backup repository"
    
    # Push to remote if configured
    if [ -n "$BACKUP_REPO_REMOTE" ]; then
        echo "Pushing to remote: $BACKUP_REPO_REMOTE"
        git remote set-url origin "$BACKUP_REPO_REMOTE" 2>/dev/null || git remote add origin "$BACKUP_REPO_REMOTE"
        
        # Try to push, handle both main and master branches
        BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
        if git push -u origin "$BRANCH" 2>/dev/null || git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null; then
            echo "✓ Successfully pushed to remote"
        else
            echo "  (Push failed - check remote configuration or authentication)"
        fi
    fi
else
    echo "  (No changes to commit - codebase is up to date)"
fi

cd - > /dev/null
echo ""
echo "✓ Backup complete"
echo ""
echo "Backup repository location: $BACKUP_REPO_DIR"
echo "Codebase size: $(du -sh codebase 2>/dev/null | cut -f1)"
echo ""
echo "To set up a remote backup, set CODEBASE_BACKUP_REMOTE environment variable:"
echo "  export CODEBASE_BACKUP_REMOTE='https://github.com/your-org/isle-dc-production-codebase-backup.git'"
echo "  $0"
