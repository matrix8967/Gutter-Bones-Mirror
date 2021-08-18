#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

export GO111MODULES=auto

go get github.com/charmbracelet/glow
go get -u github.com/jingweno/ccat
go get github.com/jesseduffield/lazydocker
go get -u github.com/sachaos/tcpterm
go get -u github.com/vultr/govultr/v2

sudo cp $GOPATH/bin/* /usr/bin/

# git -C /home/$USER/Git/Misc/ clone https://github.com/charmbracelet/glow.git
