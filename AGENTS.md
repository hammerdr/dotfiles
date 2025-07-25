# Agent Guidelines for Dotfiles Repository

## Project Type
Personal dotfiles repository containing shell configurations, Neovim setup, and installation scripts.

## Build/Test/Lint Commands
- No formal build system - this is a configuration repository
- Test configurations by running: `./install.sh` or individual install scripts
- Lua syntax check: `luac -p .config/nvim/lua/*.lua`
- Shell script validation: `shellcheck *.sh`

## Code Style Guidelines

### Lua (Neovim config)
- Use 2 spaces for indentation
- Local variables: `local var_name`
- Module requires at top: `require('module_name')`
- Function calls without parentheses when single string: `require 'module'`
- Use vim.o/vim.g for options, vim.api for API calls

### Shell Scripts
- Use `#!/bin/bash` shebang
- Quote variables: `"$variable"`
- Use `sudo` prefix for system-wide installations
- Check command existence before use

### File Organization
- Neovim config in `.config/nvim/lua/` with modular structure
- Install scripts prefixed with `install-`
- Keep dotfiles in repository root (`.zshrc`, `.tmux.conf`)

### Error Handling
- Shell scripts should use `set -e` for strict error handling
- Check command success with `&&` chaining where appropriate