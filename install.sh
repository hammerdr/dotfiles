sudo add-apt-repository -y ppa:neovim-ppa/unstable
sudo apt-get update
sudo apt-get install -y silversearcher-ag neovim
sudo $(which npm) install -g typescript typescript-language-server
sudo $(which npm) install -g pyright
sudo pip3 install --upgrade pip
sudo pip3 install python-lsp-server
sudo pip3 install pylsp-mypy
sudo pip3 install python-lsp-black
sudo pip3 install python-lsp-ruff

# Install dotfiles
mkdir -p ~/.config
cp -r .config/* ~/.config/

# Install Ghostty configuration if present
if [ -d .config/ghostty ]; then
    mkdir -p ~/.config/ghostty
    cp .config/ghostty/config ~/.config/ghostty/config
fi

# Temporarily skipping because restore might be borking things
# tmux new -d -s discord-0
# /home/discord/tmux-resurrect/scripts/restore.sh
