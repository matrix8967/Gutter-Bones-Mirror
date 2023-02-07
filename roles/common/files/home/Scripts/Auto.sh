#!/usr/bin/env bash
set -eE

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

DEBIAN=$(cat Pkglists/Debian.txt)
MANJARO=$(cat Pkglists/Manjaro.txt)
FEDORA=$(cat Pkglists/Fedora.txt)
RHEL=$(cat Pkglists/RHEL.txt)

function msg {
	echo -e "\x1B[1m$*\x1B[0m" >&2
}

trap 'msg "\x1B[31mNo Worky."' ERR

source /etc/os-release

msg "Installing Packages..."
if [[ "${ID}" =~ "debian" ]] || [[ "${ID_LIKE}" =~ "debian" ]]; then
	sudo apt-get install $DEBIAN

elif [[ "${ID}" =~ "rhel" ]] || [[ "${ID_LIKE}" =~ "fedora" ]]; then
	../Misc/RHEL_RPM_Fusion_Setup.sh && sudo dnf install $RHEL

elif [[ "${ID}" =~ "fedora" ]] || [[ "${ID_LIKE}" =~ "fedora" ]]; then
        sudo dnf install $FEDORA

elif [[ "${ID}" =~ "arch" ]] || [[ "${ID_LIKE}" =~ "arch" ]]; then
	sudo pacman -S $MANJARO

else
	msg "Unknown system ID: ${ID}"
	exit 1
fi
# echo "¯\_(ツ)_/¯ Guess it works?" >&2

echo -n "( •_•)"
sleep .75
echo -n -e "\r( •_•)>⌐■-■"
sleep .75
echo -n -e "\r               "
echo  -e "\r(⌐■_■)"
sleep .5
echo -e "\( ﾟヮﾟ)/ it werked." >&2

# Install Dev Tools

sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

git clone https://github.com/romkatv/powerlevel10k.git ~/.oh-my-zsh/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/redxtech/zsh-kitty ~/.oh-my-zsh/custom/plugins/zsh-kitty
git clone https://github.com/TamCore/autoupdate-oh-my-zsh-plugins ~/.oh-my-zsh/custom/plugins/autoupdate

cp ../Configs/Shell/zshrc ~/.zshrc
cp ../Configs/Shell/p10k.zsh ~/.p10k.zsh

# Install Tmux
cp ../Configs/Shell/tmux.conf ~/.tmux.conf
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install Vundle.
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
cp ../Configs/Shell/vimrc ~/.vimrc
vim +PluginInstall +qall
sudo cp -r /home/$USER/.vim* /root/
