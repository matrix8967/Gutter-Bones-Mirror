#!/usr/bin/env bash
set -eE

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color


function msg {
  echo -e "\x1B[1m$*\x1B[0m" >&2
}

trap 'msg "\x1B[31mNo Worky."' ERR

source /etc/os-release


msg "Installing Packages..."
if [[ "${ID}" =~ "debian" ]] || [[ "${ID_LIKE}" =~ "debian" ]]; then
    sudo apt-get install \
    git \
    iftop \
    nmap \
    curl \
    ipcalc \
    ncdu \
    pwgen \
    htop \
    wavemon \
    vim \
    tmux \
    fail2ban \
    tldr \
    s-tui \
    neofetch \
    zsh \
    fonts-powerline \
    kitty \
    ruby-full \
    build-essential \
    zlib1g-dev \
    tmux-plugin-manager \
    exfat-fuse \
    exfat-utils \
    taskwarrior \
    openvpn \
    dialog \
    python3-pip \
    python3-setuptools \
    libclang-dev \
    cifs-utils \
    neovim \
    nfs-common \
    speedtest-cli \
    tree \
    ncmpcpp \
    mpc \
    figlet \
    chafa \
    asciinema \
    lolcat \
    neovim \
    ncdu \
    tcpdump \
    mc \
    mplayer \
    most \
    imagemagick \
    cargo \
    rustc \
    golang \
    tty-clock \
    cmus \
    w3m \
    apt-transport-https \
    ddgr \
    powertop \
    virtualenv \
    pkg-config \
    httpie \
    screen \
    minicom \
    
elif [[ "${ID}" =~ "fedora" ]] || [[ "${ID_LIKE}" =~ "fedora" ]]; then
    sudo dnf install \
    git \
    dnf-plugins-core \
    lm_sensors \
    iftop \
    glances \
    curl \
    ipcalc \
    ncdu \
    ipcalc \
    pwgen \
    htop \
    wavemon \
    vim \
    nano \
    tmux \
    fail2ban \
    tldr \
    neofetch \
    zsh \
    powerline-fonts \
    steam \
    vlc \
    vlc-core \
    tilix \
    gparted \
    arc-theme \
    python-pip \
    guake \
    kitty \
    flatpak \
    util-linux-user \
    bat \
    httpie \
    golang \
    msr-tools \
    task \
    ansible \
    glogg \
    unzip \
    dmidecode \
    fwupd \
    wireshark \
    tmux \
    chafa \
    cheese \
    screen \
    minicom \
    cu \
    WoeUSB \
    ddgr \
    most \
    nodejs \
    npm \
    ruby \
    lxc \
    libvirt \
    asciinema \
    powertop \
    tlp \
    tlp-rdw \
    cargo \
    speedtest-cli \
    nfs-utils \
    thunderbird \
    mono-complete \
    figlet \
    lolcat \
    openvpn \
    xinput \
    fira-code-fonts \
    cava \
    nmap \
    cmus \
    gnome-tweaks \
    adb \
    fastboot \
    @virtualization \
    qemu \
    qemu-kvm \
    qemu-common \
    qemu-block-curl \
    qemu-block-dmg \
    qemu-block-ssh \
    qemu-device-display \
    qemu-device-usb-redirect \
    qemu-img \
    qemu-sanity-check \
    qemu-system-aarch64 \
    qemu-system-arm \
    qemu-system-mips \
    qemu-system-riscv \
    qemu-system-x86 \
    qemu-ui-gtk \
    qemu-ui-curses \
    qemu-ui-spice-app \
    unrar \
    iotop \
    lutris \
    avahi-ui \
    iperf3 \
    exif \
    wireguard \
    wg-quick \
    wireguard-tools \
    brasero \
    screen \
    minicom \
    scrcpy \
    ffmpeg \
    gedit \
    gedit-plugins \
    python3-pip \
    python3-setuptools \
    python3-libs \
    pipx \
    
elif [[ "${ID}" =~ "arch" ]] || [[ "${ID_LIKE}" =~ "arch" ]]; then
    sudo pacman -S \
    iftop \
    glances \
    ipcalc \
    ncdu \
    pwgen \
    wavemon \
    vim \
    tmux \
    fail2ban \
    tldr \
    s-tui \
    neofetch \
    tilix \
    gparted \
    guake \
    kitty \
    task \
    bat \
    lsd \
    dialog \
    neovim \
    tree \
    vis \
    ncmpcpp \
    mpc \
    figlet \
    chafa \
    asciinema \
    awesome-terminal-fonts \
    powerline-fonts \
    powerline-vim \
    arc-gtk-theme \
    unzip \
    xorg-xinput \
    lolcat \
    papirus-icon-theme \
    mlocate \
    gnome-disk-utility \
    most \
    xdotool \
    piper \
    httpie \
    rust \
    wireshark-cli \
    wireshark-qt \
    speedtest-cli \
    appimagelauncher \
    go \
    lm_sensors \
    powerline \
    powerline-vim \
    powerline-common \
    powerline-fonts \
    python-gobject \
    gtk3 \
    libappindicator-gtk3 \
    libnotify \
    polkit \
    virt-manager \
    libvirt \
    kate \
    dolphin-emu \
    dolphin-plugins \
    pcsx2 \
    scummvm \
    scummvm-tools \
    ppsspp \
    htop \
    brave \
    dnssec-tools \
    net-tools \
    qemu \
    virt-manager \
    virt-viewer \
    dnsmasq \
    vde2 \
    bridge-utils \
    openbsd-netcat \
    ebtables \
    iptables \
    libguestfs \
    python-pip \
    python-wheel \
    bootsplash-theme-arch \
    tlpui \
    zsh \

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

cp ../Configs/Shell/zshrc ~/.zshrc
cp ../Configs/Shell/p10k.zsh ~/.p10k.zsh

# Install Tmux
cp ../Configs/Shell/tmux.conf ~/.tmux.conf
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Install Vundle.
git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
cp ../Configs/Shell/vimrc ~/.vimrc
vim +PluginInstall +qall
