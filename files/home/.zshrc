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

plugins=(archlinux extract encode64 gnu-utils golang history-substring-search ipfs httpie jira jsontools kate keychain kubectl microk8s minikube nmap osx pass pip pipenv pyenv pylint python rbenv rsync ruby rust safe-paste screen shell-proxy ssh-agent sudo systemadmin systemd taskwarrior terraform themes tmux tmux-cssh tmuxinator torrent urltools vundle yum virtualenv zsh-autosuggestions zsh-syntax-highlighting gpg-agent gem git-extras firewalld docker-compose docker cp cargo bundler ansible adb)

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

# =====Editor===== #

export EDITOR="/usr/bin/vim"

# =====Kitty Config===== #

autoload -Uz compinit
compinit
# Completion for kitty
kitty + complete setup zsh | source /dev/stdin

# =====Bat/Man===== #

export MANPAGER="sh -c 'col -bx | bat -l man -p'"
#man 2 select
MANROFFOPT="-c"

# =====Docker===== #

export PATH=/usr/bin:$PATH
export DOCKER_HOST=unix:///run/user/1000/docker.sock

# =====Zsh Opts===== #

# enable completion features
autoload -Uz compinit
compinit -d ~/.cache/zcompdump
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # case insensitive tab completion

setopt appendhistory
setopt histignorealldups
setopt HIST_SAVE_NO_DUPS
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_dups       # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it

#ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=999'

# =====Aliases===== #

alias nano='vim'
alias pls='sudo'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias icat='kitty +kitten icat'
alias dm='sudo dmesg -HTL'
alias ls='lsd'
#alias bat='batcat'
alias pubkey='cat ~/.ssh/id_rsa.pub'
alias ipa='ip -color -brief -human addr'
alias http='http --check-status --pretty=all --verbose'
alias netstat_def='sudo netstat -tlnp'
alias rsync='rsync -razuvhLP --info=progress2'

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

function hs {
	history | grep "$1"
}

function keyrm {
	ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R "$1"
}

function printline {
	awk '{print $0; system("sleep .3");}' "$1"
}

function psaux {
	sudo ps awxf -eo pid,user,%cpu,%mem,args
}

function Quotes {
	echo -e "a=7; echo \$a; echo \"\$a\"; echo '\$a'; echo \"'\$a'\"; echo '\"\$a\"'"
	a=7; echo $a; echo "$a"; echo '$a'; echo "'$a'"; echo '"$a"'
}

# =====Blur for Kitty Term===== #

# if [[ $(ps --no-header -p $PPID -o comm) =~ '^yakuake|kitty$' ]]; then
#         for wid in $(xdotool search --pid $PPID); do
#             xprop -f _KDE_NET_WM_BLUR_BEHIND_REGION 32c -set _KDE_NET_WM_BLUR_BEHIND_REGION 0 -id $wid; done
# fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
