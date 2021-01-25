# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block, everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export TERM="xterm-256color"

POWERLEVEL9K_MODE='nerdfont-complete'

# =====SSH-Agent===== #
zstyle :omz:plugins:ssh-agent agent-forwarding on
zstyle :omz:plugins:ssh-agent identities

# Path to your oh-my-zsh installation.
export ZSH="/home/$USER/.oh-my-zsh"

ZSH_THEME=powerlevel10k/powerlevel10k

plugins=(adb ansible cargo colored-man-pages colorize cp docker docker-compose git git-extras httpie microk8s minikube nmap oc pip pyenv pylint python rsync ssh-agent systemadmin systemd taskwarrior tmux tmux-cssh zsh-syntax-highlighting zsh-autosuggestions)

source $ZSH/oh-my-zsh.sh

# =====MOTD===== #

# cat .ASCII/dontpanic.txt |lolcat && figlet -w 100 -l -k -f Bloody "Don't Panic!" | lolcat

# =====GoLang===== #

export GOPATH=/home/$USER/Git/Misc/Go/
export PATH=$PATH:/usr/local/go/bin

# =====Python===== #

export PATH=$PATH:~/.local/bin/

# =====Ruby===== #

export GEM_HOME=$HOME/.gems
export PATH=$HOME/.gems/bin:$PATH

# =====Rust===== #

export PATH=$PATH:~/.cargo/bin/

# =====Kitty Config===== #

# autoload -Uz compinit
# compinit
# Completion for kitty
# kitty + complete setup zsh | source /dev/stdin

# =====Aliases===== #

#alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias dm='dmesg -HTL'
alias nano='vim'
alias pls='sudo'
# alias icat='kitty +kitten icat'

# =====Zsh Opts===== #

# enable completion features
autoload -Uz compinit
compinit -d ~/.cache/zcompdump
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case insensitive tab completion

setopt appendhistory
setopt histignorealldups
setopt HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_DUPS
#setopt hist_ignore_dups
#setopt hist_ignore_space
#setopt hist_verify

# =====Functions===== #

function pvpn {
	sudo protonvpn c -f
}

function amimullvad {
	curl https://am.i.mullvad.net/connected
}

function dig_outside {
	dig +short myip.opendns.com @resolver1.opendns.com
}

function MXErgo {
	~/Scripts/./MXErgo.sh
}

function ElecomDeftPro {
	~/Scripts/./ElecomDeftPro.sh
}

function ElecomEX-GPro {
	~/Scripts/./ElecomEX-GPro.sh
}

# =====Blur for Kitty Term===== #

# if [[ $(ps --no-header -p $PPID -o comm) =~ '^yakuake|kitty$' ]]; then
#         for wid in $(xdotool search --pid $PPID); do
#             xprop -f _KDE_NET_WM_BLUR_BEHIND_REGION 32c -set _KDE_NET_WM_BLUR_BEHIND_REGION 0 -id $wid; done
# fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
