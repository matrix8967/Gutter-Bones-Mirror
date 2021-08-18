#!/usr/bin/env bash
set -eE

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

sudo snap remove lxd
sudo snap remove core18
sudo snap remove snapd
sudo apt purge snapd
