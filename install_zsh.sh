#!/bin/bash
wget https://www.zsh.org/pub/zsh-5.9.tar.xz
tar -xvf zsh-5.9.tar.xz  # Use the version you downloaded
cd zsh-5.9

# This is the key: tell it to install in your home directory
./configure --prefix=$HOME/local

make
make install

# Configuration block to be added to ~/.bashrc

export PATH="$HOME/local/bin:$PATH"
# Install Oh My Zsh without sudo
Y | sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"


ZSH_CONFIG='
# Start Zsh
if [ -f "$HOME/local/bin/zsh" ]; then
  exec $HOME/local/bin/zsh
fi
'

# Check if the configuration already exists to prevent duplication
if ! grep -q "exec \$HOME/local/bin/zsh" "$HOME/.bashrc"; then
  echo "Appending Zsh startup configuration to ~/.bashrc..."
  # Use 'echo' with the configuration block and 'tee -a' to safely append it.
  # The -a flag ensures content is appended, not overwritten.
  echo "$ZSH_CONFIG" | tee -a "$HOME/.bashrc" > /dev/null
  echo "Done. The configuration has been added to ~/.bashrc."
else
  echo "Zsh configuration already found in ~/.bashrc. Skipping update."
fi

source ~/.bashrc

# copy the config file
cp configs/zsh/.zshrc ~/.zshrc

# download plugins/themes 
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
# git clone and pass if the directory already exists
if [ -d ${ZSH_CUSTOM:-~/.oh-my-zsh/custom} ]; then
    echo "Directory ${ZSH_CUSTOM:-~/.oh-my-zsh/custom} already exists. Re-clonning"
    rm -rf ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    rm -rf ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

source ~/.zshrc
