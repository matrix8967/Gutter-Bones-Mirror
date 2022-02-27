#!/usr/bin/env bash
set -eE

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

sudo snap remove lxd
sudo snap remove core18
sudo snap remove snapd

sudo apt autoremove --purge snapd

sudo rm -rf /var/cache/snapd/

cat <<EOF | sudo tee /etc/apt/preferences.d/nosnap.pref
# To prevent repository packages from triggering the installation of Snap,
# this file forbids snapd from being installed by APT.

Package: snapd
Pin: release a=*
Pin-Priority: -10
EOF
