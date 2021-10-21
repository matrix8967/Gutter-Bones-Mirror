#!/usr/bin/env bash
set -eE

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

DEBIAN=$(cat .Debian.txt)
FEDORA=$(cat .Fedora.txt)
MANJARO=$(cat .Manjaro.txt)

function msg {
  echo -e "\x1B[1m$*\x1B[0m" >&2
}

trap 'msg "\x1B[31mNo Worky."' ERR

source /etc/os-release

msg "Installing Packages..."
if [[ "${ID}" =~ "debian" ]] || [[ "${ID_LIKE}" =~ "debian" ]]; then
    sudo apt-get install $DEBIAN

elif [[ "${ID}" =~ "fedora" ]] || [[ "${ID_LIKE}" =~ "fedora" ]]; then
    sudo dnf install $FEDORA

elif [[ "${ID}" =~ "arch" ]] || [[ "${ID_LIKE}" =~ "arch" ]]; then
  sudo pacman -S $MANJARO

else
  msg "Unknown system ID: ${ID}"
  exit 1
fi
echo "¯\_(ツ)_/¯ Guess it works?" >&2

# Install Dev Tools

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/redxtech/zsh-kitty ~/.oh-my-zsh/custom/plugins/zsh-kitty

# Install Tmux
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install Vundle.
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
vim +PluginInstall +qall
sudo cp -r /home/$USER/.vim* /root/
