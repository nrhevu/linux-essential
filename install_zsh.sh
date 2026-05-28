#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
cd "$SCRIPT_DIR"

ZSH_VERSION=5.9
ZSH_TARBALL="zsh-${ZSH_VERSION}.tar.xz"
ZSH_SRC_DIR="zsh-${ZSH_VERSION}"

if [ ! -f "$ZSH_TARBALL" ]; then
  wget "https://www.zsh.org/pub/${ZSH_TARBALL}"
fi

if [ ! -d "$ZSH_SRC_DIR" ]; then
  tar -xvf "$ZSH_TARBALL"
fi

cd "$ZSH_SRC_DIR"
./configure --prefix="$HOME/local"
make
make install
cd "$SCRIPT_DIR"

export PATH="$HOME/local/bin:$PATH"

# Install Oh My Zsh without sudo, changing shells, or launching zsh mid-script.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  oh_my_zsh_installer=$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)
  RUNZSH=no CHSH=no sh -c "$oh_my_zsh_installer"
else
  echo "Oh My Zsh already installed. Skipping installer."
fi

ZSH_CONFIG='
# Start Zsh
if [ -f "$HOME/local/bin/zsh" ]; then
  exec $HOME/local/bin/zsh
fi
'

# Check if the configuration already exists to prevent duplication.
if ! grep -q "exec \$HOME/local/bin/zsh" "$HOME/.bashrc" 2>/dev/null; then
  echo "Appending Zsh startup configuration to ~/.bashrc..."
  echo "$ZSH_CONFIG" | tee -a "$HOME/.bashrc" > /dev/null
  echo "Done. The configuration has been added to ~/.bashrc."
else
  echo "Zsh configuration already found in ~/.bashrc. Skipping update."
fi

# Copy the config file if this checkout includes one.
if [ -f configs/zsh/.zshrc ]; then
  cp configs/zsh/.zshrc "$HOME/.zshrc"
fi

ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}
mkdir -p "$ZSH_CUSTOM/plugins"

install_or_update_plugin() {
  local repo="$1"
  local dest="$2"

  if [ -d "$dest/.git" ]; then
    echo "Updating $(basename "$dest")..."
    git -C "$dest" pull --ff-only
  else
    rm -rf "$dest"
    git clone "$repo" "$dest"
  fi
}

install_or_update_plugin https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
install_or_update_plugin https://github.com/zsh-users/zsh-completions.git "$ZSH_CUSTOM/plugins/zsh-completions"
install_or_update_plugin https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

contains_plugin() {
  local needle="$1"
  shift
  local plugin

  for plugin in "$@"; do
    if [ "$plugin" = "$needle" ]; then
      return 0
    fi
  done

  return 1
}

enable_omz_plugins() {
  local zshrc="$HOME/.zshrc"
  local required=(git docker zsh-completions zsh-autosuggestions zsh-syntax-highlighting)
  local enabled=()
  local line=""
  local plugin

  touch "$zshrc"
  line=$(grep -E '^plugins=\(' "$zshrc" | head -n 1 || true)

  if [ -n "$line" ]; then
    line=${line#plugins=(}
    line=${line%)}

    for plugin in $line; do
      if [ "$plugin" != "zsh-syntax-highlighting" ] && ! contains_plugin "$plugin" "${enabled[@]}"; then
        enabled+=("$plugin")
      fi
    done
  fi

  for plugin in "${required[@]}"; do
    if [ "$plugin" != "zsh-syntax-highlighting" ] && ! contains_plugin "$plugin" "${enabled[@]}"; then
      enabled+=("$plugin")
    fi
  done

  # zsh-syntax-highlighting must be loaded after other plugins.
  enabled+=(zsh-syntax-highlighting)

  if grep -qE '^plugins=\(' "$zshrc"; then
    sed -i.bak -E "s/^plugins=\(.*\)$/plugins=(${enabled[*]})/" "$zshrc"
  else
    printf '\nplugins=(%s)\n' "${enabled[*]}" >> "$zshrc"
  fi
}

enable_omz_plugins
rm -f "$HOME"/.zcompdump*

echo "Zsh completions, autosuggestions, and syntax highlighting are installed. Open a new shell to use them."
