#!/usr/bin/env bash
set -eE

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
sudo pro config set apt_news=false
sudo snap remove --purge lxd
sudo snap remove --purge snap-store
sudo snap remove --purge core20
sudo snap remove --purge bare
sudo snap remove --purge snapd
sudo apt remove -y --purge snapd
sudo apt-mark hold snapd # avoid install snapd again
sudo apt autoremove --purge snapd

sudo rm -rf /var/cache/snapd/

cat <<EOF | sudo tee /etc/apt/preferences.d/nosnap.pref
# To prevent repository packages from triggering the installation of Snap,
# this file forbids snapd from being installed by APT.

Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF