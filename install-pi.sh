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

# Install Pi coding agent
print_info "Installing Pi coding agent..."

if ! command -v npm &> /dev/null; then
    print_error "npm not found - cannot install Pi"
    print_info "Please install Node.js and npm first"
    exit 1
fi

# Install locally to ~/node_modules (nix store npm prefix is read-only)
# This matches how opencode is installed on these machines.
print_info "Installing Pi to ~/node_modules/..."
npm install --prefix "$HOME" --ignore-scripts @earendil-works/pi-coding-agent
print_progress "Pi coding agent installed"

# Verify the binary exists
PI_BIN="$HOME/node_modules/.bin/pi"
if [ -x "$PI_BIN" ]; then
    PI_VERSION=$("$PI_BIN" --version 2>/dev/null || echo "unknown")
    print_progress "Pi version: $PI_VERSION"
else
    # Fall back to checking the package bin directly
    PI_BIN="$HOME/node_modules/@earendil-works/pi-coding-agent/dist/cli.js"
    if [ -f "$PI_BIN" ]; then
        print_progress "Pi installed (binary at node_modules/.bin/pi)"
    else
        print_error "Pi binary not found after install"
    fi
fi

# Symlink Pi global config from dotfiles
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_AGENT_DIR="$HOME/.pi/agent"

print_info "Installing Pi configuration..."
mkdir -p "$HOME/.pi"

if [ -d "$PI_AGENT_DIR" ] && [ ! -L "$PI_AGENT_DIR" ]; then
    print_info "Backing up existing ~/.pi/agent to ~/.pi/agent.backup"
    mv "$PI_AGENT_DIR" "$PI_AGENT_DIR.backup"
fi

ln -sf "$SCRIPT_DIR/.pi/agent" "$PI_AGENT_DIR"
print_progress "Pi configuration installed (~/.pi/agent -> dotfiles)"

echo
echo "Pi setup complete. Authenticate with:"
echo "  pi             # then /login for subscription providers"
echo "  export ANTHROPIC_API_KEY=sk-ant-...  # or set an API key"
echo
echo "Make sure ~/node_modules/.bin is in your PATH (should be via .zshrc)."
