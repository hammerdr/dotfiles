#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_progress() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[→]${NC} $1"
}

print_info "Installing opencode configuration..."

if [ ! -d .opencode ]; then
    print_error "No .opencode directory found in dotfiles"
    exit 1
fi

mkdir -p ~/.opencode

if [ -d ~/.opencode ] && [ ! -L ~/.opencode ]; then
    print_info "Backing up existing .opencode directory to .opencode.backup"
    mv ~/.opencode ~/.opencode.backup
fi

ln -sf "$PWD/.opencode" ~/.opencode
print_progress "opencode configuration installed"

if [ -d .opencode/agents ]; then
    AGENT_COUNT=$(find .opencode/agents -name "*.md" | wc -l)
    print_progress "Installed $AGENT_COUNT custom agent(s)"
fi
