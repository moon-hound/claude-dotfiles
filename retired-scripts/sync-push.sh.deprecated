#!/bin/bash
# Auto-commit and push changes to claude-dotfiles

cd ~/claude-dotfiles || exit 1

# Check if there are changes
if [[ -n $(git status --porcelain) ]]; then
    git add -A
    git commit -m "Auto-sync: $(date '+%Y-%m-%d %H:%M:%S') from $(hostname)"
    git push origin main 2>&1 | grep -v "Everything up-to-date"
fi
