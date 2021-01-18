#!/bin/bash

# Copy to /etc/update-motd.d/00-motd and make sure .hushlogin is off and showmotd is showing in sshconfig.
# Modified from https://github.com/yboetz/motd

# /usr/bin/env figlet "$(hostname)"

# get load averages
IFS=" " read LOAD1 LOAD5 LOAD15 <<<$(cat /proc/loadavg | awk '{ print $1,$2,$3 }')
# get free memory
IFS=" " read USED FREE TOTAL <<<$(free -htm | grep "Mem" | awk {'print $3,$4,$2'})
# get processes
PROCESS=`ps -eo user=|sort|uniq -c | awk '{ print $2 " " $1 }'`
PROCESS_ALL=`echo "$PROCESS"| awk {'print $2'} | awk '{ SUM += $1} END { print SUM }'`
PROCESS_ROOT=`echo "$PROCESS"| grep root | awk {'print $2'}`
PROCESS_USER=`echo "$PROCESS"| grep -v root | awk {'print $2'} | awk '{ SUM += $1} END { print SUM }'`
# get processors
PROCESSOR_NAME=`grep "model name" /proc/cpuinfo | cut -d ' ' -f3- | awk {'print $0'} | head -1`
PROCESSOR_COUNT=`grep -ioP 'processor\t:' /proc/cpuinfo | wc -l`

W="\e[0;39m"
G="\e[1;32m"

echo -e "
${W}system info:
$W  Distro......: $W`cat /etc/*release | grep "PRETTY_NAME" | cut -d "=" -f 2- | sed 's/"//g'`
$W  Kernel......: $W`uname -sr`

$W  Uptime......: $W`uptime -p`
$W  Load........: $G$LOAD1$W (1m), $G$LOAD5$W (5m), $G$LOAD15$W (15m)
$W  Processes...:$W $G$PROCESS_ROOT$W (root), $G$PROCESS_USER$W (user), $G$PROCESS_ALL$W (total)

$W  CPU.........: $W$PROCESSOR_NAME ($G$PROCESSOR_COUNT$W vCPU)
$W  Memory......: $G$USED$W used, $G$FREE$W free, $G$TOTAL$W total$W"

printf "\n"
uptime -p

# config
max_usage=90
bar_width=50
# colors
white="\e[39m"
green="\e[1;32m"
red="\e[1;31m"
dim="\e[2m"
undim="\e[0m"

# disk usage: ignore zfs, squashfs & tmpfs
mapfile -t dfs < <(df -H -x zfs -x squashfs -x tmpfs -x devtmpfs --output=target,pcent,size | tail -n+2)
printf "\ndisk usage:\n"

for line in "${dfs[@]}"; do
    # get disk usage
    usage=$(echo "$line" | awk '{print $2}' | sed 's/%//')
    used_width=$((($usage*$bar_width)/100))
    # color is green if usage < max_usage, else red
    if [ "${usage}" -ge "${max_usage}" ]; then
        color=$red
    else
        color=$green
    fi
    # print green/red bar until used_width
    bar="[${color}"
    for ((i=0; i<$used_width; i++)); do
        bar+="="
    done
    # print dimmmed bar until end
    bar+="${white}${dim}"
    for ((i=$used_width; i<$bar_width; i++)); do
        bar+="="
    done
    bar+="${undim}]"
    # print usage line & bar
    echo "${line}" | awk '{ printf("%-31s%+3s used out of %+4s\n", $1, $2, $3); }' | sed -e 's/^/  /'
    echo -e "${bar}" | sed -e 's/^/  /'
done

# config
MAX_TEMP=40

# disks to check
disks=(sda sdb sdc)
logfiles='/var/log/syslog /var/log/syslog.1'

# get all lines with smartd entries from syslog
mapfile -t lines < <(grep -hiP 'smartd\[[[:digit:]]+\]:' $logfiles | grep -iP "(Temperature_Celsius|previous self-test)" | sort -r)

out=""
for i in "${!disks[@]}"; do
    disk=${disks[$i]}
    uuid=$(blkid -s UUID -o value "/dev/${disk}")
    #mapfile -t disklines < <(printf -- '%s\n' "${lines[@]}" | grep "${uuid}")
    temp=$(printf -- '%s\n' "${lines[@]}" | grep "${uuid}" | grep -m 1 "Temperature_Celsius" | awk '{ print $NF }')
    status=$(printf -- '%s\n' "${lines[@]}" | grep "${uuid}" | grep -m 1 -oP "previous self-test.*" | cut -d' '  -f4-)
    # color green if temp <= MAX_TEMP, else red
    if [[ "${temp}" -gt "${MAX_TEMP}" ]]; then
        color=$red
    else
        color=$green
    fi
    # if temp > 80 assume reading is wrong and set temp to "--"
    if [[ "${temp}" -gt 80 ]]; then
        temp="--"
    fi
    # color green if status is "without error", else red
    if [[ "${status}" == "without error" ]]; then
        status_color=$green
    else
        status_color=$red
    fi
    # print temp & smartd error
    out+="${disk}:,${color}${temp}C${undim} | ${status_color}${status}${undim},"
    # insert \n every $COLUMNS column
    if [ $((($i+1) % $COLUMNS)) -eq 0 ]; then
        out+="\n"
    fi
done
out+="\n"

printf "\nsmartd status:\n"
printf "$out" | column -ts $',' | sed -e 's/^/  /'

services=("fail2ban" "ufw" "lxd" "netdata" "zed" "smartd" "postfix")
# sort services
IFS=$'\n' services=($(sort <<<"${services[*]}"))
unset IFS

service_status=()
# get status of all services
for service in "${services[@]}"; do
    service_status+=($(systemctl is-active "$service"))
done

out=""
for i in ${!services[@]}; do
    # color green if service is active, else red
    if [[ "${service_status[$i]}" == "active" ]]; then
        out+="${services[$i]}:,${green}${service_status[$i]}${undim},"
    else
        out+="${services[$i]}:,${red}${service_status[$i]}${undim},"
    fi
    # insert \n every $COLUMNS column
    if [ $((($i+1) % $COLUMNS)) -eq 0 ]; then
        out+="\n"
    fi
done
out+="\n"

printf "\nservices:\n"
printf "$out" | column -ts $',' | sed -e 's/^/  /'

logfile='/var/log/fail2ban.log*'
mapfile -t lines < <(grep -hioP '(\[[a-z-]+\]) (ban|unban)' $logfile | sort | uniq -c)
jails=($(printf -- '%s\n' "${lines[@]}" | grep -oP '\[\K[^\]]+' | sort | uniq))

out=""
for jail in ${jails[@]}; do
    bans=$(printf -- '%s\n' "${lines[@]}" | grep -iP "[[:digit:]]+ \[$jail\] ban" | awk '{print $1}')
    unbans=$(printf -- '%s\n' "${lines[@]}" | grep -iP "[[:digit:]]+ \[$jail\] unban" | awk '{print $1}')
    diff=$(($bans-$unbans))
    out+=$(printf "$jail, %+3s bans, %+3s unbans, %+3s active" $bans $unbans $diff)"\n"
done

# fail2ban-client status to get all jails, takes about ~70ms
jails=($(fail2ban-client status | grep "Jail list:" | sed "s/ //g" | awk '{split($2,a,",");for(i in a) print a[i]}'))

out="jail,failed,total,banned,total\n"

for jail in ${jails[@]}; do
    # slow because fail2ban-client has to be called for every jail (~70ms per jail)
    status=$(fail2ban-client status ${jail})
    failed=$(echo "$status" | grep -ioP '(?<=Currently failed:\t)[[:digit:]]+')
    totalfailed=$(echo "$status" | grep -ioP '(?<=Total failed:\t)[[:digit:]]+')
    banned=$(echo "$status" | grep -ioP '(?<=Currently banned:\t)[[:digit:]]+')
    totalbanned=$(echo "$status" | grep -ioP '(?<=Total banned:\t)[[:digit:]]+')
    out+="$jail,$failed,$totalfailed,$banned,$totalbanned\n"
done

printf "\nfail2ban status:\n"
printf $out | column -ts $',' | sed -e 's/^/  /'

mapfile -t containers < <(docker ps -a --format '{{.Names}}\t{{.Status}}' | awk '{ print $1,$2 }')

out=""
for i in "${!containers[@]}"; do
    IFS=" " read name status <<< ${containers[i]}
    # color green if service is active, else red
    if [[ "${status}" == "Up" ]]; then
        out+="${name}:,${green}${status,,}${undim},"
    else
        out+="${name}:,${red}${status,,}${undim},"
    fi
    # insert \n every $COLUMNS column
    if [ $((($i+1) % $COLUMNS)) -eq 0 ]; then
        out+="\n"
    fi
done
out+="\n"

printf "\ndocker status:\n"
printf "$out" | column -ts $',' | sed -e 's/^/  /'
