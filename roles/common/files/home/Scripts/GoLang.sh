#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

export GO111MODULES=auto

go install github.com/charmbracelet/glow@latest
go install github.com/maaslalani/draw@latest
# go get -u github.com/jingweno/ccat
go install github.com/jesseduffield/lazydocker@latest
go install github.com/sachaos/tcpterm@latest
# go get -u github.com/vultr/govultr/v2
go install github.com/gonetx/httpit@latest
go install github.com/jesseduffield/lazygit@latest
go install github.com/jmhobbs/terminal-parrot@latest
# go get github.com/cointop-sh/cointop
go install github.com/cointop-sh/cointop@latest
go install github.com/charmbracelet/gum@latest
go install github.com/maaslalani/gambit@latest
go install github.com/maaslalani/cue@latest
go install github.com/c-grimshaw/gosniff@latest
go install github.com/maaslalani/slides@latest
go install github.com/fabio42/ssl-checker@latest


sudo cp $GOPATH/bin/* /usr/bin/

# git -C /home/$USER/Git/Misc/ clone https://github.com/charmbracelet/glow.git
