#!/bin/bash
# Script to backup production docker-compose.yml to a separate git repository
# This creates a private backup repository structure

set -e

cd /root/isle-dc-production

BACKUP_REPO_DIR="/root/isle-dc-production-backup"
BACKUP_REPO_REMOTE="${BACKUP_REPO_REMOTE:-}"  # Set this environment variable if you have a remote

echo "=== Production docker-compose.yml Git Backup ==="
echo ""

# Initialize backup repository if it doesn't exist
if [ ! -d "$BACKUP_REPO_DIR" ]; then
    echo "Creating backup repository at $BACKUP_REPO_DIR..."
    mkdir -p "$BACKUP_REPO_DIR"
    cd "$BACKUP_REPO_DIR"
    git init
    echo "docker-compose.yml.backup" > .gitignore
    echo "*.backup" >> .gitignore
    git add .gitignore
    git commit -m "Initial commit: Production docker-compose.yml backup repository"
    cd - > /dev/null
    echo "✓ Backup repository initialized"
fi

# Copy docker-compose.yml to backup repo
if [ -f docker-compose.yml ]; then
    echo "Copying docker-compose.yml to backup repository..."
    cp docker-compose.yml "${BACKUP_REPO_DIR}/docker-compose.yml"
    cd "$BACKUP_REPO_DIR"
    
    # Add and commit if there are changes
    if ! git diff --quiet docker-compose.yml 2>/dev/null || ! git ls-files --error-unmatch docker-compose.yml >/dev/null 2>&1; then
        git add docker-compose.yml
        git commit -m "Backup: Production docker-compose.yml $(date +%Y-%m-%d\ %H:%M:%S)"
        echo "✓ Changes committed to backup repository"
        
        # Push to remote if configured
        if [ -n "$BACKUP_REPO_REMOTE" ]; then
            echo "Pushing to remote: $BACKUP_REPO_REMOTE"
            git remote set-url origin "$BACKUP_REPO_REMOTE" 2>/dev/null || git remote add origin "$BACKUP_REPO_REMOTE"
            BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
            if git push -u origin "$BRANCH" 2>/dev/null || git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null; then
                echo "✓ Successfully pushed to remote"
            else
                echo "  (Push failed - check authentication or remote configuration)"
            fi
        elif git remote get-url origin >/dev/null 2>&1; then
            # If remote is already configured, try to push
            echo "Pushing to configured remote..."
            BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
            if git push -u origin "$BRANCH" 2>/dev/null || git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null; then
                echo "✓ Successfully pushed to remote"
            else
                echo "  (Push failed - check authentication)"
            fi
        fi
    else
        echo "  (No changes to commit)"
    fi
    
    cd - > /dev/null
    echo ""
    echo "✓ Backup complete"
    echo ""
    echo "Backup repository location: $BACKUP_REPO_DIR"
    echo "To set up a remote backup, set BACKUP_REPO_REMOTE environment variable:"
    echo "  export BACKUP_REPO_REMOTE='https://github.com/your-org/isle-dc-production-backup.git'"
    echo "  $0"
else
    echo "Error: docker-compose.yml not found!"
    exit 1
fi
