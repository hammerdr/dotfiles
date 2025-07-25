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
    echo "🚀 Starting macOS dotfiles setup..."
fi
echo

if [ "$NVIM_ONLY" = false ]; then
    # Check if Homebrew is installed
    print_info "Checking for Homebrew..."
    if ! command -v brew &> /dev/null; then
        print_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        print_progress "Homebrew installed"
    else
        print_progress "Homebrew already installed"
    fi

    # Update Homebrew
    print_info "Updating Homebrew..."
    brew update
    print_progress "Homebrew updated"

    # Install packages
    print_info "Installing packages..."

    # Install silver searcher (ag)
    print_info "Installing silver searcher..."
    brew install the_silver_searcher
    print_progress "Silver searcher installed"

    # Install Neovim
    print_info "Installing Neovim..."
    brew install neovim
    print_progress "Neovim installed"

    # Install Node.js if not present
    if ! command -v node &> /dev/null; then
        print_info "Installing Node.js..."
        brew install node
        print_progress "Node.js installed"
    else
        print_progress "Node.js already installed"
    fi

    # Install TypeScript and TypeScript Language Server
    print_info "Installing TypeScript and language servers..."
    npm install -g typescript typescript-language-server
    print_progress "TypeScript and TypeScript Language Server installed"

    # Install Pyright
    print_info "Installing Pyright..."
    npm install -g pyright
    print_progress "Pyright installed"

    # Install Python if not present
    if ! command -v python3 &> /dev/null; then
        print_info "Installing Python 3..."
        brew install python@3
        print_progress "Python 3 installed"
    else
        print_progress "Python 3 already installed"
    fi

    # Upgrade pip
    print_info "Upgrading pip..."
    python3 -m pip install --upgrade pip
    print_progress "pip upgraded"

    # Install Python LSP packages
    print_info "Installing Python LSP server and plugins..."
    pip3 install python-lsp-server
    print_progress "python-lsp-server installed"

    pip3 install pylsp-mypy
    print_progress "pylsp-mypy installed"

    pip3 install python-lsp-black
    print_progress "python-lsp-black installed"

    pip3 install python-lsp-ruff
    print_progress "python-lsp-ruff installed"
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

# Copy Ghostty configuration
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
    echo "✨ macOS dotfiles setup complete!"
    echo
    echo "You may need to:"
    echo "  • Restart your terminal for changes to take effect"
    echo "  • Add Homebrew to your PATH if this is a fresh install"
    echo "  • Source your shell configuration: source ~/.zshrc"
    echo "  • Open Neovim and run :PackerSync to install plugins"
fi