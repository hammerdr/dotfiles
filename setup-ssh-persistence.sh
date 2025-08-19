#!/bin/bash

set -e

print_info() {
    echo -e "\033[1;34mℹ\033[0m $1"
}

print_success() {
    echo -e "\033[1;32m✓\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m✗\033[0m $1"
}

print_info "Setting up SSH persistence and modal connections..."

# Create SSH sockets directory
if [ ! -d "$HOME/.ssh/sockets" ]; then
    mkdir -p "$HOME/.ssh/sockets"
    chmod 700 "$HOME/.ssh/sockets"
    print_success "Created SSH sockets directory"
else
    print_success "SSH sockets directory already exists"
fi

# Backup existing SSH config
if [ -f "$HOME/.ssh/config" ]; then
    cp "$HOME/.ssh/config" "$HOME/.ssh/config.backup.$(date +%Y%m%d_%H%M%S)"
    print_success "Backed up existing SSH config"
fi

# Copy new SSH config
cp ".ssh-config" "$HOME/.ssh/config"
chmod 600 "$HOME/.ssh/config"
print_success "Updated SSH config with ControlMaster settings"

print_info "Setup complete!"
echo
echo "Next steps:"
echo "1. Ready to use! Default host is set to: coder.hammer-default"
echo "2. Use 'remote' command to connect in persistent mode"
echo "3. Use 'local' command to switch back to local mode"
echo "4. Use 'ssh-status' to check connection status"
echo
echo "Keybindings in Ghostty:"
echo "- Cmd+Shift+R: New remote tab (auto-connects to coder.hammer-default)"
echo "- Cmd+Shift+L: New local tab"
echo
echo "Quick start:"
echo "  remote  # Connect to coder.hammer-default"
echo "  # Open new tabs with Cmd+Shift+R - they'll auto-connect!"
echo "  local   # Switch back to local mode"
echo
echo "To use a different server:"
echo "  export REMOTE_HOST='user@hostname'"