# Claude Code Dotfiles

Synced configuration for Claude Code across multiple machines.

## What's Synced

- **skills/** - Custom slash commands
- **hooks/** - Shell scripts for automation
- **rules/** - Code quality and security guidelines
- **scripts/** - Helper scripts
- **agents/** - Custom agent definitions
- **settings.local.json** - Local settings overlay
- **CLAUDE.md** - Project instructions

## What's NOT Synced

- Session history and state
- Cache files
- Machine-specific paths (plugins, settings.json symlinks)

## Setup on New Machine

```bash
# Clone repo
cd ~
git clone git@github.com:moon-hound/claude-dotfiles.git

# Run setup script
./claude-dotfiles/setup.sh
```

## How It Works

- **Auto-pull on session start** - Pulls latest configs when Claude Code starts
- **Auto-commit/push on changes** - Commits and pushes when configs change
- Symlinks keep .claude/ pointing to repo
