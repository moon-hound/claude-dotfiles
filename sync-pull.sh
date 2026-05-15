#!/bin/bash
# Auto-pull latest changes from claude-dotfiles

cd ~/claude-dotfiles || exit 1

# Stash any local changes, pull, and re-apply
if [[ -n $(git status --porcelain) ]]; then
    git stash save "Auto-stash before pull $(date '+%Y-%m-%d %H:%M:%S')"
    git pull --rebase origin main
    git stash pop 2>/dev/null
else
    git pull --rebase origin main 2>&1 | grep -v "Already up to date"
fi
