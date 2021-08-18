#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

cargo install lsd bat bottom bandwhich mdbook procs du-dust watchexec-cli ripgrep cloak checkpwn taskwarrior-tui gpg-tui

sudo setcap cap_sys_ptrace,cap_dac_read_search,cap_net_raw,cap_net_admin+ep $(which bandwhich)

# https://sn0int.readthedocs.io/en/latest/install.html
