#!/bin/bash
# Script to set up and push docker-compose backup to GitHub
# Similar to the codebase backup setup

set -e

cd /root/isle-dc-production-backup

REMOTE_URL="https://github.com/sstoker/islandora-isle-dc-production-docker-compose-backup.git"

echo "=== Setting up Docker Compose Backup Remote Repository ==="
echo ""

# Check if remote is already configured
if git remote get-url origin >/dev/null 2>&1; then
    CURRENT_REMOTE=$(git remote get-url origin)
    echo "Current remote: $CURRENT_REMOTE"
    
    if [ "$CURRENT_REMOTE" != "$REMOTE_URL" ]; then
        echo "Updating remote URL..."
        git remote set-url origin "$REMOTE_URL"
        echo "✓ Remote updated"
    else
        echo "✓ Remote is already configured correctly"
    fi
else
    echo "Adding remote repository..."
    git remote add origin "$REMOTE_URL"
    echo "✓ Remote added"
fi

# Ensure we're on main branch
git branch -M main 2>/dev/null || git branch -M master 2>/dev/null || true
CURRENT_BRANCH=$(git branch --show-current)

echo ""
echo "=== Repository Status ==="
echo "Local branch: $CURRENT_BRANCH"
echo "Commits: $(git rev-list --count HEAD)"
echo "Files: $(git ls-files | wc -l)"
echo ""

# Check if repository exists on GitHub
echo "Checking if remote repository exists..."
if git ls-remote --heads origin main >/dev/null 2>&1 || git ls-remote --heads origin master >/dev/null 2>&1; then
    echo "✓ Remote repository exists on GitHub"
    echo ""
    echo "Pushing to remote..."
    
    if git push -u origin "$CURRENT_BRANCH" 2>&1; then
        echo ""
        echo "✓ Successfully pushed to remote!"
        echo "Repository URL: $REMOTE_URL"
    else
        echo ""
        echo "⚠ Push failed. Check authentication or repository permissions."
    fi
else
    echo "⚠ Remote repository not found on GitHub"
    echo ""
    echo "You need to create the repository on GitHub first:"
    echo ""
    echo "Steps:"
    echo "  1. Go to: https://github.com/new"
    echo "  2. Repository name: islandora-isle-dc-production-docker-compose-backup"
    echo "  3. Description: Private backup repository for production docker-compose.yml"
    echo "  4. Make it PRIVATE (important for production config!)"
    echo "  5. Do NOT initialize with README, .gitignore, or license"
    echo "  6. Click 'Create repository'"
    echo ""
    echo "Then run this script again:"
    echo "  $0"
    echo ""
    echo "Or push manually:"
    echo "  cd /root/isle-dc-production-backup"
    echo "  git push -u origin $CURRENT_BRANCH"
fi

echo ""
echo "=== Current Configuration ==="
echo "Remote URL: $(git remote get-url origin 2>/dev/null || echo 'Not set')"
echo "Branch: $CURRENT_BRANCH"
echo ""
