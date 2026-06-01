# Global Agent Instructions

## Identity
Personal coding environment for a staff content designer at Discord working on growth experiments, push notifications, and copy generation.

## General Preferences
- Be concise. This runs in a terminal.
- Prefer editing existing files over creating new ones.
- Use `nvim` as the editor (aliased as `vi`/`vim`).
- Shell is zsh with oh-my-zsh and powerlevel10k.
- When writing shell scripts: use `#!/bin/bash`, quote variables, use `set -e`.

## Tools & Environment
- Primary workspace: Linux (Coder/cloud dev) and macOS (local)
- Dotfiles managed in `~/dotfiles` with `~/personalize` bootstrap
- Kubernetes access via `kubectl`, `kubectx`, `kubens`
- Git workflow: feature branches, PRs via `gh`

## Code Style
- Shell: bash, quote vars, check command existence before use
- Lua (Neovim): 2-space indent, local variables, vim.o/vim.g for options
- TypeScript: follow project conventions
