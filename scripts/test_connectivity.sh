#!/bin/bash
# ====================
# GUTTER BONEZ QUICK CONNECTIVITY TEST
# ====================
# Quick SSH connectivity test for all inventory groups
# Usage: ./scripts/test_connectivity.sh [group_name]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INVENTORY_FILE="${SCRIPT_DIR}/../inventory/Inventory01.ini"
ANSIBLE_CONFIG="${SCRIPT_DIR}/../ansible.cfg"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "SUCCESS") echo -e "${GREEN}✓${NC} $message" ;;
        "FAILED")  echo -e "${RED}✗${NC} $message" ;;
        "WARNING") echo -e "${YELLOW}!${NC} $message" ;;
        "INFO")    echo -e "${BLUE}i${NC} $message" ;;
    esac
}

# Function to test a specific group
test_group() {
    local group=$1
    print_status "INFO" "Testing group: $group"

    if ansible $group -i "$INVENTORY_FILE" -m ping --one-line -f 10 2>/dev/null | grep -q SUCCESS; then
        success_count=$(ansible $group -i "$INVENTORY_FILE" -m ping --one-line -f 10 2>/dev/null | grep SUCCESS | wc -l)
        total_count=$(ansible $group -i "$INVENTORY_FILE" --list-hosts 2>/dev/null | grep -c "hosts" || echo "0")
        print_status "SUCCESS" "Group '$group': $success_count/$total_count hosts reachable"

        # Show individual host results
        ansible $group -i "$INVENTORY_FILE" -m ping --one-line -f 10 2>/dev/null | while read line; do
            if echo "$line" | grep -q SUCCESS; then
                host=$(echo "$line" | cut -d'|' -f1 | xargs)
                print_status "SUCCESS" "  $host"
            elif echo "$line" | grep -q UNREACHABLE; then
                host=$(echo "$line" | cut -d'|' -f1 | xargs)
                print_status "FAILED" "  $host (UNREACHABLE)"
            fi
        done
    else
        print_status "FAILED" "Group '$group': No hosts reachable"
    fi
    echo
}

# Function to test network devices with raw commands
test_network_devices() {
    local group=$1
    print_status "INFO" "Testing network devices in group: $group"

    # Use raw module for network devices
    ansible $group -i "$INVENTORY_FILE" -m raw -a "echo 'SSH test successful'" --one-line -f 10 2>/dev/null | while read line; do
        if echo "$line" | grep -q SUCCESS; then
            host=$(echo "$line" | cut -d'|' -f1 | xargs)
            print_status "SUCCESS" "  $host (SSH accessible)"
        elif echo "$line" | grep -q UNREACHABLE; then
            host=$(echo "$line" | cut -d'|' -f1 | xargs)
            print_status "FAILED" "  $host (UNREACHABLE)"
        fi
    done
    echo
}

# Main execution
main() {
    print_status "INFO" "Starting Gutter Bonez connectivity tests..."
    print_status "INFO" "Using inventory: $INVENTORY_FILE"
    echo

    # Check if inventory file exists
    if [[ ! -f "$INVENTORY_FILE" ]]; then
        print_status "FAILED" "Inventory file not found: $INVENTORY_FILE"
        exit 1
    fi

    # If specific group provided, test only that group
    if [[ $# -eq 1 ]]; then
        local target_group=$1
        print_status "INFO" "Testing specific group: $target_group"

        # Check if it's a network device group
        if [[ "$target_group" =~ ^(ubiquiti_routers|asus_routers|other_routers|unifi_devices|network_devices)$ ]]; then
            test_network_devices "$target_group"
        else
            test_group "$target_group"
        fi
        exit 0
    fi

    # Test all major groups
    print_status "INFO" "Testing all groups..."
    echo

    # Test Linux systems
    print_status "INFO" "=== LINUX SYSTEMS ==="
    test_group "production_linux"
    test_group "apple"
    test_group "vmnet"

    # Test network devices (special handling)
    print_status "INFO" "=== NETWORK DEVICES ==="
    test_network_devices "ubiquiti_routers"
    test_network_devices "asus_routers"
    test_network_devices "other_routers"
    test_network_devices "unifi_devices"

    # Test remote systems
    print_status "INFO" "=== REMOTE SYSTEMS ==="
    test_group "styx_internal"
    test_group "vultr_hosts"
    test_group "linode_hosts"

    print_status "INFO" "Connectivity test completed!"
}

# Help function
show_help() {
    cat << EOF
Gutter Bonez Connectivity Test Script

Usage: $0 [group_name]

Without arguments: Tests all groups
With group_name: Tests specific group only

Available groups:
  Linux Systems:
    - production_linux    (Local Linux hosts)
    - apple              (Mac systems)
    - vmnet              (VM network)

  Network Devices:
    - ubiquiti_routers   (EdgeRouter, ERX)
    - asus_routers       (ASUSWRT-Merlin)
    - other_routers      (MikroTik, R7000)
    - unifi_devices      (UniFi APs)

  Remote Systems:
    - styx_internal      (Via Styx jumphost)
    - vultr_hosts        (Vultr cloud)
    - linode_hosts       (Linode cloud)

  Logical Groups:
    - linux              (All Linux systems)
    - network_devices    (All network gear)
    - remote             (All remote systems)
    - production         (Local production)

Examples:
  $0                           # Test everything
  $0 production_linux          # Test only production Linux hosts
  $0 network_devices           # Test all network devices
  $0 asus_routers             # Test only ASUS routers

EOF
}

# Handle command line arguments
case "${1:-}" in
    -h|--help|help)
        show_help
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
