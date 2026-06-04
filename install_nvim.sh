curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
chmod u+x nvim-linux-x86_64.appimage
sudo mkdir -p /opt/nvim
sudo mv nvim-linux-x86_64.appimage /opt/nvim/nvim
sudo ln -sf /opt/nvim/nvim /usr/local/bin/nvim
git clone https://github.com/NvChad/starter ~/.config/nvim
