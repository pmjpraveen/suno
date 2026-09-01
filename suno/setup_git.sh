# Suno - Quick Start Script

## 🚀 Run This to Initialize Git and Push

Save this as `setup_git.sh` and run it:

```bash
#!/bin/bash

echo "🎙️ Suno - Git Setup Script"
echo "============================"
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check if git is initialized
echo -e "${BLUE}Step 1: Checking git...${NC}"
if [ -d .git ]; then
    echo -e "${GREEN}✓ Git already initialized${NC}"
else
    echo -e "${YELLOW}Initializing git repository...${NC}"
    git init
    echo -e "${GREEN}✓ Git initialized${NC}"
fi
echo ""

# Step 2: Add all files
echo -e "${BLUE}Step 2: Adding files to git...${NC}"
git add .
echo -e "${GREEN}✓ Files added${NC}"
echo ""

# Step 3: Show status
echo -e "${BLUE}Step 3: Git status:${NC}"
git status --short
echo ""

# Step 4: Create initial commit
echo -e "${BLUE}Step 4: Creating initial commit...${NC}"
if git rev-parse HEAD > /dev/null 2>&1; then
    echo -e "${YELLOW}Repository already has commits${NC}"
else
    git commit -m "🎉 Initial commit: Suno v1.0 - Meeting recorder milestone 1

Features:
- Menu bar app with recording controls
- M4A and WAV audio format support  
- Recording management and persistence
- macOS 15.0+ with SwiftUI and AVFoundation
- Full MVVM architecture
- Comprehensive documentation

Milestone 1 complete ✅"
    echo -e "${GREEN}✓ Initial commit created${NC}"
fi
echo ""

# Step 5: Set main branch
echo -e "${BLUE}Step 5: Setting main branch...${NC}"
git branch -M main
echo -e "${GREEN}✓ Branch set to main${NC}"
echo ""

# Step 6: Prompt for GitHub repository
echo -e "${BLUE}Step 6: GitHub Setup${NC}"
echo -e "${YELLOW}Do you want to add a GitHub remote? (y/n)${NC}"
read -r add_remote

if [ "$add_remote" = "y" ] || [ "$add_remote" = "Y" ]; then
    echo -e "${YELLOW}Enter your GitHub username:${NC}"
    read -r github_user
    
    echo -e "${YELLOW}Enter repository name (default: suno):${NC}"
    read -r repo_name
    repo_name=${repo_name:-suno}
    
    remote_url="https://github.com/$github_user/$repo_name.git"
    
    if git remote get-url origin > /dev/null 2>&1; then
        echo -e "${YELLOW}Remote 'origin' already exists. Update it? (y/n)${NC}"
        read -r update_remote
        if [ "$update_remote" = "y" ] || [ "$update_remote" = "Y" ]; then
            git remote set-url origin "$remote_url"
            echo -e "${GREEN}✓ Remote updated: $remote_url${NC}"
        fi
    else
        git remote add origin "$remote_url"
        echo -e "${GREEN}✓ Remote added: $remote_url${NC}"
    fi
    echo ""
    
    echo -e "${YELLOW}Push to GitHub now? (y/n)${NC}"
    read -r do_push
    
    if [ "$do_push" = "y" ] || [ "$do_push" = "Y" ]; then
        echo -e "${BLUE}Pushing to GitHub...${NC}"
        git push -u origin main
        echo -e "${GREEN}✓ Pushed to GitHub!${NC}"
        echo ""
        echo -e "${GREEN}🎉 Success! Your repository is now on GitHub:${NC}"
        echo -e "${BLUE}   https://github.com/$github_user/$repo_name${NC}"
    fi
else
    echo -e "${YELLOW}Skipping GitHub setup${NC}"
    echo -e "${BLUE}You can add remote later with:${NC}"
    echo "   git remote add origin https://github.com/YOUR_USERNAME/suno.git"
    echo "   git push -u origin main"
fi

echo ""
echo -e "${GREEN}============================"
echo -e "✅ Git setup complete!"
echo -e "============================${NC}"
echo ""

# Show final status
echo -e "${BLUE}Repository status:${NC}"
git log --oneline -n 3 2>/dev/null || echo "No commits yet"
echo ""
git remote -v 2>/dev/null || echo "No remotes configured"
echo ""

echo -e "${BLUE}Next steps:${NC}"
echo "1. Create repository on GitHub (if not done)"
echo "2. Verify files are pushed correctly"
echo "3. Update README_GITHUB.md with your info"
echo "4. Add topics/tags to repository"
echo "5. Start coding! 🚀"
echo ""
