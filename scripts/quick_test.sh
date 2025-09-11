#!/bin/bash
# ====================
# GUTTER BONEZ QUICK TEST RUNNER
# ====================
# Fast connectivity and functionality tests
# Usage: ./scripts/quick_test.sh [test_type]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INVENTORY_FILE="$PROJECT_DIR/inventory/Inventory01.ini"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Print functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
header() { echo -e "${PURPLE}[TEST]${NC} $1"; }

# Quick ping test
quick_ping() {
    local group=$1
    local timeout=${2:-5}

    header "Quick ping test for group: $group"

    if ! ansible-inventory -i "$INVENTORY_FILE" --list | grep -q "\"$group\""; then
        error "Group '$group' not found in inventory"
        return 1
    fi

    ansible $group -i "$INVENTORY_FILE" -m ping -f 20 --timeout=$timeout 2>/dev/null | \
    while IFS= read -r line; do
        if [[ $line =~ SUCCESS ]]; then
            host=$(echo "$line" | cut -d'|' -f1 | xargs)
            success "✓ $host"
        elif [[ $line =~ (UNREACHABLE|FAILED) ]]; then
            host=$(echo "$line" | cut -d'|' -f1 | xargs)
            error "✗ $host"
        fi
    done
    echo
}

# Network device test
test_network() {
    header "Testing network devices"

    # ASUS routers (Linux-based)
    info "Testing ASUS routers..."
    ansible asus_routers -i "$INVENTORY_FILE" -m raw -a "uname -a" --timeout=10 2>/dev/null | \
    grep -E "(SUCCESS|UNREACHABLE)" | while IFS= read -r line; do
        host=$(echo "$line" | cut -d'|' -f1 | xargs)
        if [[ $line =~ SUCCESS ]]; then
            success "✓ $host (ASUSWRT-Merlin)"
        else
            error "✗ $host"
        fi
    done

    # Ubiquiti routers
    info "Testing Ubiquiti routers..."
    ansible ubiquiti_routers -i "$INVENTORY_FILE" -m raw -a "show version | head -1" --timeout=10 2>/dev/null | \
    grep -E "(SUCCESS|UNREACHABLE)" | while IFS= read -r line; do
        host=$(echo "$line" | cut -d'|' -f1 | xargs)
        if [[ $line =~ SUCCESS ]]; then
            success "✓ $host (EdgeOS)"
        else
            error "✗ $host"
        fi
    done

    echo
}

# Production systems test
test_production() {
    header "Testing production systems"
    quick_ping "production_linux" 8
}

# Remote systems test
test_remote() {
    header "Testing remote systems via jumphost"
    quick_ping "remote" 15
}

# DNS and ctrld test
test_dns() {
    header "Testing DNS and ctrld on Linux hosts"

    ansible linux -i "$INVENTORY_FILE" -m shell -a "nslookup verify.controld.com && systemctl is-active ctrld 2>/dev/null || echo 'ctrld not running'" --timeout=10 2>/dev/null | \
    while IFS= read -r line; do
        if [[ $line =~ \| ]]; then
            host=$(echo "$line" | cut -d'|' -f1 | xargs)
            if [[ $line =~ SUCCESS ]]; then
                success "✓ $host (DNS + ctrld check)"
            else
                warning "! $host (DNS/ctrld issues)"
            fi
        fi
    done
    echo
}

# Full connectivity test
test_all() {
    header "Running comprehensive connectivity test"

    info "Testing production Linux hosts..."
    quick_ping "production_linux" 8

    info "Testing Apple devices..."
    quick_ping "apple" 8

    info "Testing VM network..."
    quick_ping "vmnet" 5

    test_network
    test_remote

    success "All tests completed!"
}

# System info quick check
test_info() {
    header "Quick system information check"

    ansible linux -i "$INVENTORY_FILE" -m shell -a "echo \$(hostname): \$(uptime | cut -d',' -f1)" --one-line --timeout=8 2>/dev/null | \
    grep SUCCESS | while IFS= read -r line; do
        host=$(echo "$line" | cut -d'|' -f1 | xargs)
        uptime_info=$(echo "$line" | grep -o 'up.*')
        info "$host - $uptime_info"
    done
    echo
}

# Check inventory syntax
check_inventory() {
    header "Checking inventory syntax"

    if ansible-inventory -i "$INVENTORY_FILE" --list >/dev/null 2>&1; then
        success "Inventory syntax is valid"

        # Show group counts
        info "Group summary:"
        ansible-inventory -i "$INVENTORY_FILE" --list | jq -r '
        .["_meta"]["hostvars"] | keys | length as $total |
        "  Total hosts: \($total)"
        ' 2>/dev/null || info "  (Install jq for detailed group info)"
    else
        error "Inventory syntax errors found!"
        ansible-inventory -i "$INVENTORY_FILE" --list
        return 1
    fi
    echo
}

# Show available hosts
list_hosts() {
    header "Available hosts by group"

    for group in production_linux apple vmnet ubiquiti_routers asus_routers other_routers unifi_devices styx_internal vultr_hosts linode_hosts; do
        if ansible-inventory -i "$INVENTORY_FILE" --list | grep -q "\"$group\""; then
            hosts=$(ansible $group -i "$INVENTORY_FILE" --list-hosts 2>/dev/null | tail -n +2 | xargs | tr ' ' ',')
            if [[ -n "$hosts" ]]; then
                info "$group: $hosts"
            fi
        fi
    done
    echo
}

# Help function
show_help() {
    cat << EOF
Gutter Bonez Quick Test Runner

Usage: $0 [test_type]

Test Types:
  ping          - Quick ping test for all groups
  production    - Test production subnet hosts
  network       - Test network devices (routers, APs)
  remote        - Test remote hosts via jumphost
  dns           - Test DNS resolution and ctrld status
  info          - Quick system information
  inventory     - Check inventory syntax
  list          - List all hosts by group
  all           - Run all connectivity tests (default)

Examples:
  $0                 # Run all tests
  $0 production      # Test only production hosts
  $0 network         # Test only network devices
  $0 dns             # Check DNS and ctrld

Quick Commands:
  # Test specific group
  ansible production_linux -i inventory/Inventory01.ini -m ping

  # Check specific host
  ansible RPi5 -i inventory/Inventory01.ini -m shell -a "uptime"

  # Run network command on routers
  ansible asus_routers -i inventory/Inventory01.ini -m raw -a "uname -a"

EOF
}

# Main execution
main() {
    info "Gutter Bonez Quick Test Runner"
    info "Using inventory: $INVENTORY_FILE"
    echo

    # Check if inventory exists
    if [[ ! -f "$INVENTORY_FILE" ]]; then
        error "Inventory file not found: $INVENTORY_FILE"
        exit 1
    fi

    case "${1:-all}" in
        ping|p)
            quick_ping "all" 10
            ;;
        production|prod)
            test_production
            ;;
        network|net)
            test_network
            ;;
        remote|rem)
            test_remote
            ;;
        dns|d)
            test_dns
            ;;
        info|i)
            test_info
            ;;
        inventory|inv|check)
            check_inventory
            ;;
        list|l)
            list_hosts
            ;;
        all|a|*)
            test_all
            ;;
        help|h|-h|--help)
            show_help
            ;;
    esac
}

# Run main function
main "$@"
