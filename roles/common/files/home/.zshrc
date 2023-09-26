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

plugins=(zsh-kitty archlinux extract encode64 gnu-utils golang history-substring-search ipfs httpie jira jsontools kate keychain kubectl microk8s minikube nmap macos pass pip pipenv pyenv pylint python rbenv rsync ruby rust safe-paste screen shell-proxy ssh-agent sudo systemadmin systemd taskwarrior terraform themes tmux tmux-cssh tmuxinator torrent urltools vundle yum virtualenv zsh-autosuggestions zsh-syntax-highlighting gpg-agent gem git-extras firewalld docker-compose docker cp rust bundler aws autoupdate ansible adb)

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
# kitty + complete setup zsh | source /dev/stdin
# zinit light redxtech/zsh-kitty

# =====Bat/Man===== #

export MANPAGER="sh -c 'col -bx | bat -l man -p'"
# man 2 select
# MANROFFOPT="-c"

# =====Docker===== #

export PATH=/usr/bin:$PATH
export DOCKER_HOST=unix:///run/user/1000/docker.sock

# =====PostmarketOS===== #

autoload bashcompinit
bashcompinit
eval "$(register-python-argcomplete pmbootstrap)"

# =====1PasswordCLI===== #

# eval "$(op completion zsh)"; compdef _op op

# =====Ansible===== #

export ANSIBLE_NOCOWS=1

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

export HISTORY_IGNORE="(ls|cd|pwd|exit|sudo reboot|history|cd -|cd ..)"

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
alias rsync='rsync -razuvhLP'
alias tree='tree -shuC'
alias wifi_scan='nmcli device wifi list'
alias cat='bat -pp'
alias db9='screen -dmLS USG-screen /dev/ttyUSB0 115200,cs8'
alias lsssh='ps aux | egrep "sshd: [a-zA-Z]+@"'
alias xpaste='xclip -out -sel clipboard'
alias xcopy='xclip -in -sel clipboard'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias psa="ps auxf"
alias psgrep="ps aux | grep -v grep | grep -i -e VSZ -e"
alias psmem='ps auxf | sort -nr -k 4'
alias pscpu='ps auxf | sort -nr -k 3'

# =====Functions===== #

function pvpn-connect {
	protonvpn-cli connect --fastest
}

function pvpn-status {
	protonvpn-cli status
}

function pvpn-view {
	nmcli connection show --active
}

function pvpn-reset-ks {
	nmcli connection delete pvpn-ipv6leak-protection && nmcli connection delete pvpn-killswitch
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

function typer {
	text="$1"
	delay="$2"

	for i in $(seq 0 $(expr length "${text}")) ; do
		echo -n "${text:$i:1}"
		sleep ${delay}
	done
}

function psaux {
	sudo ps awxf -eo pid,user,%cpu,%mem,args
}

function Quotes {
	echo -e "a=7; echo \$a; echo \"\$a\"; echo '\$a'; echo \"'\$a'\"; echo '\"\$a\"'"
	a=7; echo $a; echo "$a"; echo '$a'; echo "'$a'"; echo '"$a"'
}

function cpu_temp() {
	# Init result
	local result=0.00
	# The first line of this file is x1000.
	# Read the first line from the file.
	line=$(head -n 1 /sys/class/thermal/thermal_zone0/temp)
	# Test if the string is an integer as expected with a regex.
	if [[ $line =~ ^-?[0-9]+$ ]]
	then
		# Convert temp to Celcius & store as string.
		result=$(awk "BEGIN {printf \"%.2f\n\", $line/1000}")
	fi
	# The gud gud. Or maybe bad bad?
	echo -e "Current CPU Temp is: $result°C"
}

function Gitlab_Pull {
	for dir in ~/Git/Gitlab/*/; do
		git -C $dir pull
	done
}

function Github_Pull {
	for dir in ~/Git/Github/*/; do
		git -C $dir pull
	done
}

function Dir_Pull {
	for dir in $(pwd)/*/; do
		git -C $dir pull
	done
}

function strip_IPs {
	sed -E -r 's/(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)/$IP_ADDRESSES/g' $1
}

function spotifydl {
	spotify_dl -k -w -l "$1" -o ~/Music
}

function vid_dl {
	ffmpeg -user_agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/601.7.8(KHTML, like Gecko) Version/9.1.3 Safari/537.86.7" -i "$1" -c:v copy -c:a copy -f mpegts "$2"
}

function ADB_Text {
	text=$(printf '%s%%s' ${@})
	text=${text%%%s}
	text=${text//\'/\\\'}
	text=${text//\"/\\\"}
	adb shell input text "$text"
	adb shell input keyevent 66

}

function rpi_bl_off {
	sudo chown -R $USER:$USER /sys/devices/platform/rpi_backlight/backlight/rpi_backlight/bl_power && echo 1 > /sys/devices/platform/rpi_backlight/backlight/rpi_backlight/bl_power
}

function rpi_bl_on {
	sudo chown -R $USER:$USER /sys/devices/platform/rpi_backlight/backlight/rpi_backlight/bl_power && echo 0 > /sys/devices/platform/rpi_backlight/backlight/rpi_backlight/bl_power
}

function git_log {
	git log --graph --abbrev-commit --no-decorate --date=format:'%Y-%m-%d %H:%M:%S'\'' --format=format:'\''%C(8)%>|(16)%h %C(7)%ad %C(8)%&lt;(16,trunc)%an %C(auto)%d%>|(1)%s'\'' --all'

}

# =====Blur for Kitty Term===== #

# if [[ $(ps --no-header -p $PPID -o comm) =~ '^yakuake|kitty$' ]]; then
#         for wid in $(xdotool search --pid $PPID); do
#             xprop -f _KDE_NET_WM_BLUR_BEHIND_REGION 32c -set _KDE_NET_WM_BLUR_BEHIND_REGION 0 -id $wid; done
# fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
