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

msg "Checking OS & Installing Tailscale"
if [[ "${ID}" =~ "debian" ]] || [[ "${ID_LIKE}" =~ "debian" ]]; then

    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add -
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list
    sudo apt-get update
    sudo apt-get install tailscale
    echo -e "Auth with sudo tailscale up"
    sudo systemctl start tailscaled
    sudo tailscale up

elif [[ "${ID}" =~ "fedora" ]] || [[ "${ID_LIKE}" =~ "fedora" ]]; then

    sudo dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo
    sudo dnf install tailscale
    echo -e "Use sudo systemctl enable --now tailscaled to enable the tailscale service."
    echo -e "Auth with sudo tailscale up"
    sudo systemctl start tailscaled
    sudo tailscale up

elif [[ "${ID}" =~ "arch" ]] || [[ "${ID_LIKE}" =~ "arch" ]]; then

    sudo pacman -S tailscale
    echo -e "Use sudo systemctl enable --now tailscaled to enable the tailscale service."
    echo -e "Auth with sudo tailscale up"
    sudo systemctl start tailscaled
    sudo tailscale up

else
  msg "Unknown system ID: ${ID}"
  msg "Please add support for your distribution to: $0"
  exit 1
fi
echo "¯\_(ツ)_/¯ Guess it works?" >&2
