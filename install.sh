#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Progress indicator
print_progress() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[→]${NC} $1"
}

# Parse command line arguments
NVIM_ONLY=false
for arg in "$@"; do
    case $arg in
        --nvim-only)
            NVIM_ONLY=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --nvim-only    Only install Neovim configuration"
            echo "  -h, --help     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

if [ "$NVIM_ONLY" = true ]; then
    echo "🚀 Installing Neovim configuration only..."
else
    echo "🚀 Starting Linux dotfiles setup..."
fi
echo

if [ "$NVIM_ONLY" = false ]; then
    # Update package lists
    print_info "Updating package lists..."
    sudo apt-get update
    print_progress "Package lists updated"

    # Add Neovim PPA
    print_info "Adding Neovim PPA..."
    sudo add-apt-repository -y ppa:neovim-ppa/unstable
    print_progress "Neovim PPA added"

    # Update package lists again after adding PPA
    print_info "Updating package lists after PPA addition..."
    sudo apt-get update
    print_progress "Package lists updated"

    # Install system packages
    print_info "Installing system packages (silver searcher, neovim, fzf)..."
    sudo apt-get install -y silversearcher-ag neovim fzf
    print_progress "System packages installed"

    # Install Node.js packages if npm is available
    if command -v npm &> /dev/null; then
        print_info "Installing TypeScript and language servers..."
        sudo $(which npm) install -g typescript typescript-language-server
        print_progress "TypeScript and TypeScript Language Server installed"

        print_info "Installing Pyright..."
        sudo $(which npm) install -g pyright
        print_progress "Pyright installed"
    else
        print_error "npm not found - skipping Node.js packages"
        print_info "Please install Node.js and npm, then run this script again"
    fi

    # Install Python packages if pip3 is available
    if command -v pip3 &> /dev/null; then
        print_info "Upgrading pip..."
        sudo pip3 install --upgrade pip
        print_progress "pip upgraded"

        print_info "Installing Python LSP server and plugins..."
        sudo pip3 install python-lsp-server
        print_progress "python-lsp-server installed"

        sudo pip3 install pylsp-mypy
        print_progress "pylsp-mypy installed"

        sudo pip3 install python-lsp-black
        print_progress "python-lsp-black installed"

        sudo pip3 install python-lsp-ruff
        print_progress "python-lsp-ruff installed"
    else
        print_error "pip3 not found - skipping Python packages"
        print_info "Please install Python 3 and pip3, then run this script again"
    fi

    # Install fzf key bindings and completion
    print_info "Setting up fzf key bindings and completion..."
    if [ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
        echo "# fzf key bindings and completion" >> ~/.zshrc.fzf
        echo "source /usr/share/doc/fzf/examples/key-bindings.zsh" >> ~/.zshrc.fzf
        echo "source /usr/share/doc/fzf/examples/completion.zsh" >> ~/.zshrc.fzf
        print_progress "fzf key bindings configured"
    else
        print_info "fzf key bindings not found - they may be in a different location"
    fi

    # Install oh-my-zsh plugins
    print_info "Installing oh-my-zsh plugins..."

    # Install zsh-autosuggestions
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        print_info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        print_progress "zsh-autosuggestions installed"
    else
        print_progress "zsh-autosuggestions already installed"
    fi

    # Install zsh-syntax-highlighting
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        print_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
        print_progress "zsh-syntax-highlighting installed"
    else
        print_progress "zsh-syntax-highlighting already installed"
    fi
fi

# Install dotfiles
echo
if [ "$NVIM_ONLY" = true ]; then
    print_info "Installing Neovim configuration..."
else
    print_info "Installing dotfiles..."
fi

# Create .config directory if it doesn't exist
mkdir -p ~/.config

# Copy Neovim configuration
print_info "Installing Neovim configuration..."
cp -r .config/* ~/.config/
print_progress "Neovim configuration installed"

# Install Ghostty configuration if present
if [ -d .config/ghostty ]; then
    print_info "Installing Ghostty configuration..."
    mkdir -p ~/.config/ghostty
    cp .config/ghostty/config ~/.config/ghostty/config
    print_progress "Ghostty configuration installed"
fi

if [ "$NVIM_ONLY" = false ]; then
    # Symlink shell configuration
    print_info "Installing shell configuration..."
    if [ -f ~/.zshrc ]; then
        print_info "Backing up existing .zshrc to .zshrc.backup"
        mv ~/.zshrc ~/.zshrc.backup
    fi
    ln -sf "$PWD/.zshrc" ~/.zshrc
    print_progress ".zshrc installed"

    # Symlink tmux configuration
    print_info "Installing tmux configuration..."
    if [ -f ~/.tmux.conf ]; then
        print_info "Backing up existing .tmux.conf to .tmux.conf.backup"
        mv ~/.tmux.conf ~/.tmux.conf.backup
    fi
    ln -sf "$PWD/.tmux.conf" ~/.tmux.conf
    print_progress ".tmux.conf installed"

    # Symlink Claude configuration
    if [ -d .claude ]; then
        print_info "Installing Claude configuration..."
        if [ -d ~/.claude ]; then
            print_info "Backing up existing .claude directory to .claude.backup"
            mv ~/.claude ~/.claude.backup
        fi
        ln -sf "$PWD/.claude" ~/.claude
        print_progress "Claude configuration installed"
    fi
fi

echo
if [ "$NVIM_ONLY" = true ]; then
    echo "✨ Neovim configuration installation complete!"
    echo
    echo "You may need to:"
    echo "  • Open Neovim and run :PackerSync to install plugins"
    echo "  • Restart Neovim for all changes to take effect"
else
    echo "✨ Linux dotfiles setup complete!"
    echo
    echo "You may need to:"
    echo "  • Restart your terminal for changes to take effect"
    echo "  • Source your shell configuration: source ~/.zshrc"
    echo "  • Open Neovim and run :PackerSync to install plugins"
    if ! command -v npm &> /dev/null; then
        echo "  • Install Node.js and npm for TypeScript support"
    fi
    if ! command -v pip3 &> /dev/null; then
        echo "  • Install Python 3 and pip3 for Python LSP support"
    fi
fi

# Temporarily skipping because restore might be borking things
# tmux new -d -s discord-0
# /home/discord/tmux-resurrect/scripts/restore.sh
