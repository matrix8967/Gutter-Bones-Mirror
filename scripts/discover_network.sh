#!/bin/bash
# ====================
# GUTTER BONEZ NETWORK DISCOVERY & VALIDATION
# ====================
# Discovers available hosts and validates inventory configuration
# Usage: ./scripts/discover_network.sh [subnet|validate|ping|scan]

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
CYAN='\033[0;36m'
NC='\033[0m'

# Print functions
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }
header() { echo -e "${PURPLE}[DISCOVERY]${NC} $1"; }
debug() { echo -e "${CYAN}[DEBUG]${NC} $1"; }

# Get current network information
get_network_info() {
    header "Gathering network information"

    # Get default gateway and interface
    DEFAULT_GW=$(ip route | grep default | awk '{print $3}' | head -1)
    DEFAULT_IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    CURRENT_IP=$(ip addr show "$DEFAULT_IFACE" | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
    CURRENT_SUBNET=$(ip route | grep "$DEFAULT_IFACE" | grep -E "192\.168|10\.|172\." | awk '{print $1}' | head -1)

    info "Current IP: $CURRENT_IP"
    info "Default Gateway: $DEFAULT_GW"
    info "Default Interface: $DEFAULT_IFACE"
    info "Current Subnet: $CURRENT_SUBNET"
    echo
}

# Discover active hosts on current subnet
discover_subnet() {
    header "Discovering hosts on current subnet"

    if [[ -z "$CURRENT_SUBNET" ]]; then
        error "Could not determine current subnet"
        return 1
    fi

    info "Scanning subnet: $CURRENT_SUBNET"

    # Use nmap if available, otherwise use ping sweep
    if command -v nmap >/dev/null 2>&1; then
        info "Using nmap for host discovery..."
        nmap -sn "$CURRENT_SUBNET" 2>/dev/null | grep -E "Nmap scan report|MAC Address" | while read line; do
            if [[ $line =~ "Nmap scan report for" ]]; then
                host=$(echo "$line" | awk '{print $NF}')
                success "Found: $host"
            fi
        done
    else
        info "Using ping sweep for host discovery..."

        # Extract network portion
        NETWORK=$(echo "$CURRENT_SUBNET" | cut -d'/' -f1 | cut -d'.' -f1-3)

        # Ping sweep common addresses
        for i in {1..254}; do
            ip="$NETWORK.$i"
            if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
                success "Found: $ip"
            fi
        done
    fi
    echo
}

# Check inventory hosts against current network
validate_inventory() {
    header "Validating inventory hosts against current network"

    # Extract IPs from inventory
    inventory_ips=$(grep "ansible_host=" "$INVENTORY_FILE" | sed 's/.*ansible_host=//' | awk '{print $1}' | sort -u)

    info "Checking inventory hosts..."
    echo

    reachable=0
    unreachable=0

    for ip in $inventory_ips; do
        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            # Find hostname for this IP
            hostname=$(grep "ansible_host=$ip" "$INVENTORY_FILE" | awk '{print $1}' | head -1)

            if ping -c 1 -W 2 "$ip" >/dev/null 2>&1; then
                success "✓ $hostname ($ip) - REACHABLE"
                ((reachable++))
            else
                error "✗ $hostname ($ip) - UNREACHABLE"
                ((unreachable++))
            fi
        else
            # It's a hostname, try to resolve
            hostname="$ip"
            if ping -c 1 -W 2 "$hostname" >/dev/null 2>&1; then
                resolved_ip=$(ping -c 1 "$hostname" 2>/dev/null | grep PING | awk '{print $3}' | tr -d '()')
                success "✓ $hostname ($resolved_ip) - REACHABLE"
                ((reachable++))
            else
                error "✗ $hostname - UNREACHABLE"
                ((unreachable++))
            fi
        fi
    done

    echo
    info "Summary: $reachable reachable, $unreachable unreachable"
    echo
}

# Quick ping test for specific IPs
quick_ping() {
    header "Quick ping test for common inventory IPs"

    # Common IPs from gutter_bonez inventory
    declare -A common_hosts=(
        ["10.10.10.5"]="RPi5"
        ["10.10.10.10"]="Darlene"
        ["10.10.10.1"]="Edgerouter"
        ["10.10.10.85"]="AsusGTAX6000"
        ["10.10.10.80"]="AsusRTAX58U"
        ["192.168.100.182"]="Ubuntu-VM"
    )

    for ip in "${!common_hosts[@]}"; do
        hostname="${common_hosts[$ip]}"
        if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
            success "✓ $hostname ($ip)"
        else
            debug "✗ $hostname ($ip)"
        fi
    done
    echo
}

# Port scan for SSH on discovered hosts
scan_ssh() {
    header "Scanning for SSH services"

    if [[ -z "$1" ]]; then
        error "Please provide IP or subnet to scan"
        return 1
    fi

    target="$1"
    ports=(22 8967 2222)  # Common SSH ports

    info "Scanning $target for SSH services..."

    if command -v nmap >/dev/null 2>&1; then
        for port in "${ports[@]}"; do
            info "Checking port $port..."
            nmap -p "$port" --open "$target" 2>/dev/null | grep -E "open|filtered" | while read line; do
                if [[ $line =~ "open" ]]; then
                    success "SSH found on port $port"
                fi
            done
        done
    else
        info "nmap not available, using basic connection test"
        for port in "${ports[@]}"; do
            if timeout 2 bash -c "</dev/tcp/$target/$port" 2>/dev/null; then
                success "Port $port is open on $target"
            fi
        done
    fi
    echo
}

# Generate network report
generate_report() {
    header "Generating network discovery report"

    report_file="/tmp/gutter_bonez_network_report.txt"
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    cat > "$report_file" << EOF
========================================
GUTTER BONEZ NETWORK DISCOVERY REPORT
========================================
Generated: $timestamp
Host: $(hostname)
User: $(whoami)

========================================
CURRENT NETWORK CONFIGURATION
========================================
Current IP: $CURRENT_IP
Default Gateway: $DEFAULT_GW
Default Interface: $DEFAULT_IFACE
Current Subnet: $CURRENT_SUBNET

========================================
INVENTORY HOST STATUS
========================================
EOF

    # Add inventory validation to report
    inventory_ips=$(grep "ansible_host=" "$INVENTORY_FILE" | sed 's/.*ansible_host=//' | awk '{print $1}' | sort -u)

    for ip in $inventory_ips; do
        if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            hostname=$(grep "ansible_host=$ip" "$INVENTORY_FILE" | awk '{print $1}' | head -1)
            if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
                echo "✓ REACHABLE - $hostname ($ip)" >> "$report_file"
            else
                echo "✗ UNREACHABLE - $hostname ($ip)" >> "$report_file"
            fi
        fi
    done

    cat >> "$report_file" << EOF

========================================
RECOMMENDATIONS
========================================
1. Verify you're connected to the correct network
2. Check VPN connections if accessing remote infrastructure
3. Verify SSH key authentication is set up
4. Test individual host connectivity manually

For manual testing:
  ssh azazel@10.10.10.5 -p 8967    # Test RPi5
  ssh Matrix@10.10.10.1 -p 8967    # Test Edgerouter

========================================
EOF

    success "Report saved to: $report_file"
    echo
}

# Show help
show_help() {
    cat << EOF
Gutter Bonez Network Discovery & Validation

Usage: $0 [command]

Commands:
  subnet      - Discover all hosts on current subnet
  validate    - Check inventory hosts against current network
  ping        - Quick ping test for common inventory IPs
  scan <ip>   - Scan for SSH services on specific IP/subnet
  report      - Generate comprehensive network report
  info        - Show current network information
  all         - Run all discovery and validation (default)

Examples:
  $0                    # Full discovery and validation
  $0 validate           # Check inventory hosts only
  $0 scan 10.10.10.0/24 # Scan production subnet for SSH
  $0 ping               # Quick ping test

Network Requirements:
- Must be on same network as target hosts
- May require VPN connection for remote infrastructure
- SSH keys should be configured for authentication

EOF
}

# Main execution
main() {
    info "Gutter Bonez Network Discovery & Validation"
    info "Using inventory: $INVENTORY_FILE"
    echo

    # Get network info first
    get_network_info

    case "${1:-all}" in
        subnet|s)
            discover_subnet
            ;;
        validate|v)
            validate_inventory
            ;;
        ping|p)
            quick_ping
            ;;
        scan)
            if [[ -n "$2" ]]; then
                scan_ssh "$2"
            else
                error "Scan command requires IP or subnet argument"
                show_help
            fi
            ;;
        report|r)
            generate_report
            ;;
        info|i)
            # Network info already shown
            ;;
        all|a)
            quick_ping
            validate_inventory
            generate_report
            ;;
        help|h|-h|--help)
            show_help
            ;;
        *)
            warning "Unknown command: $1"
            show_help
            ;;
    esac
}

# Check dependencies
check_deps() {
    if ! command -v ping >/dev/null 2>&1; then
        error "ping command not found"
        exit 1
    fi

    if ! command -v nmap >/dev/null 2>&1; then
        warning "nmap not found - using basic connectivity tests"
        info "Install nmap for enhanced discovery: sudo apt install nmap"
    fi
}

# Run dependency check and main function
check_deps
main "$@"
