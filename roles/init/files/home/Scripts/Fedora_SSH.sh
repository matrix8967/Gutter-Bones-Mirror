#!/usr/bin/env bash
set -eE

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

read -p "Enter new SSH Port Number: " PORT

# Commenting out the `sed` line for this script:
# The script is placed by Ansible - which also takes care of the `sshd_config` file modifications.
# -----
# sudo sed -i "s/^#Port 22$/Port $PORT/g" /etc/ssh/sshd_config

sudo semanage port -a -t ssh_port_t -p tcp $PORT

sudo firewall-cmd --add-port=$PORT/tcp --permanent

sudo firewall-cmd --reload

sudo firewall-cmd --remove-service=sshd --permanent

sudo sshd -t && sudo systemctl restart sshd

sudo firewall-cmd --reload
