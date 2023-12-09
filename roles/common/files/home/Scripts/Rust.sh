#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

cargo install apkeep bandwhich bat battop bottom cargo-bundle cargo-update checkpwn cloak czkawka_cli du-dust gitui gpg-tui gping hx libreddit lsd ludusavi mdbook names navi onefetch petname pfetch pixfetch procsqfetch rage rfetch ripgrep rustdesk rustscan sniffnet taskwarrior-tui toipe watchexec-cli ytop

sudo setcap cap_sys_ptrace,cap_dac_read_search,cap_net_raw,cap_net_admin+ep $(which bandwhich)
