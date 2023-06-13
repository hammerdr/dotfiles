sudo add-apt-repository -y ppa:neovim-ppa/unstable
sudo apt-get update
sudo apt-get install -y silversearcher-ag neovim
sudo npm install -g typescript typescript-language-server
sudo npm install -g pyright
sudo pip install --upgrade pip
sudo pip install python-lsp-server
sudo pip install pylsp-mypy
sudo pip install python-lsp-black
sudo pip install python-lsp-ruff
# Temporarily skipping because restore might be borking things
# tmux new -d -s discord-0
# /home/discord/tmux-resurrect/scripts/restore.sh
