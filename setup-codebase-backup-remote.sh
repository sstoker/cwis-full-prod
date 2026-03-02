#!/bin/bash
# Script to set up and push to the remote codebase backup repository
# This will help you create the GitHub repository and push the initial backup

set -e

cd /root/isle-dc-production-codebase-backup

REMOTE_URL="https://github.com/sstoker/islandora-isle-dc-production-codebase-backup.git"

echo "=== Setting up Codebase Backup Remote Repository ==="
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

echo ""
echo "=== Repository Status ==="
echo "Local branch: $(git branch --show-current)"
echo "Commits: $(git rev-list --count HEAD)"
echo "Files: $(git ls-files | wc -l)"
echo ""

# Check if repository exists on GitHub
echo "Checking if remote repository exists..."
if git ls-remote --heads origin main >/dev/null 2>&1 || git ls-remote --heads origin master >/dev/null 2>&1; then
    echo "✓ Remote repository exists on GitHub"
    echo ""
    echo "Pushing to remote..."
    BRANCH=$(git branch --show-current)
    
    if git push -u origin "$BRANCH" 2>&1; then
        echo ""
        echo "✓ Successfully pushed to remote!"
        echo "Repository URL: $REMOTE_URL"
    else
        echo ""
        echo "⚠ Push failed. This might be because:"
        echo "  1. The repository doesn't exist on GitHub yet"
        echo "  2. Authentication is required"
        echo ""
        echo "To create the repository on GitHub:"
        echo "  1. Go to: https://github.com/new"
        echo "  2. Repository name: islandora-isle-dc-production-codebase-backup"
        echo "  3. Make it PRIVATE (important for production code!)"
        echo "  4. Do NOT initialize with README, .gitignore, or license"
        echo "  5. Click 'Create repository'"
        echo ""
        echo "Then run this script again to push:"
        echo "  $0"
    fi
else
    echo "⚠ Remote repository not found on GitHub"
    echo ""
    echo "You need to create the repository on GitHub first:"
    echo ""
    echo "Steps:"
    echo "  1. Go to: https://github.com/new"
    echo "  2. Repository name: islandora-isle-dc-production-codebase-backup"
    echo "  3. Description: Private backup repository for production Islandora codebase"
    echo "  4. Make it PRIVATE (important for production code!)"
    echo "  5. Do NOT initialize with README, .gitignore, or license"
    echo "  6. Click 'Create repository'"
    echo ""
    echo "Then run this script again:"
    echo "  $0"
    echo ""
    echo "Or push manually:"
    echo "  cd /root/isle-dc-production-codebase-backup"
    echo "  git push -u origin main"
fi

echo ""
echo "=== Current Configuration ==="
echo "Remote URL: $(git remote get-url origin 2>/dev/null || echo 'Not set')"
echo "Branch: $(git branch --show-current)"
echo ""
