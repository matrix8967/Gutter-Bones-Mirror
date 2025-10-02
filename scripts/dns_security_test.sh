#!/bin/bash
# Production DNS Security Testing Script for Gutter Bonez
# Runs DNS security tests against remote hosts from workstation
# Results are automatically fetched back to local workstation

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PLAYBOOK_PATH="${PROJECT_ROOT}/playbooks/dns_security_testing.yml"
RESULTS_BASE="/tmp/gutter_bonez_dns_security"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default configuration
DEFAULT_INVENTORY="inventory/hosts.yml"
DEFAULT_TESTS='["baseline","malicious_blocking"]'
DEFAULT_ENVIRONMENT="production"
CONTROLD_INTEGRATION=false
FAIL_ON_CRITICAL=false
VERBOSE=""
HOST_LIMIT=""
CHECK_MODE=""

print_usage() {
    cat << EOF
${CYAN}DNS Security Testing Framework - Production Usage${NC}

${YELLOW}USAGE:${NC}
    $0 [OPTIONS] -i INVENTORY_FILE

${YELLOW}OPTIONS:${NC}
    -i, --inventory FILE     Ansible inventory file (required)
    -l, --limit PATTERN      Limit to specific hosts/groups
    -t, --tests TESTS        JSON array of tests to run
                            Default: ${DEFAULT_TESTS}
    -e, --environment ENV    Test environment name
                            Default: ${DEFAULT_ENVIRONMENT}
    -c, --controld          Enable Control D integration tests
    -f, --fail-critical     Fail on critical security issues
    -v, --verbose           Verbose output (-v, -vv, -vvv)
    --check                 Run in check mode (no changes)
    -h, --help              Show this help message

${YELLOW}AVAILABLE TESTS:${NC}
    baseline             Basic DNS functionality and health
    malicious_blocking   Threat protection and filtering
    https_interception   Certificate chain analysis
    captive_portal       Captive portal detection
    secure_dns           DoH/DoT protocol testing
    rebinding_protection DNS rebinding attack prevention
    dnssec              DNSSEC validation

${YELLOW}EXAMPLES:${NC}
    # Basic health check on all hosts
    $0 -i inventory/routers.yml

    # Comprehensive audit on specific router group
    $0 -i inventory/network.yml -l routers -t '["baseline","malicious_blocking","https_interception"]'

    # Control D integration test
    $0 -i inventory/controld_hosts.yml --controld -e "controld_testing"

    # Critical security audit (fails on issues)
    $0 -i inventory/production.yml --fail-critical -t '["baseline","malicious_blocking","captive_portal"]'

    # Check mode (dry run)
    $0 -i inventory/test.yml --check -v

${YELLOW}INVENTORY EXAMPLES:${NC}
    # Simple SSH inventory
    [routers]
    asus-router ansible_host=192.168.1.1 ansible_user=admin

    # With SSH key
    [servers]
    test-server ansible_host=10.0.1.100 ansible_user=azazel ansible_ssh_private_key_file=~/.ssh/test_key

    # Windows hosts
    [windows]
    win-client ansible_host=192.168.1.50 ansible_user=admin ansible_connection=winrm

${YELLOW}RESULTS:${NC}
    Results are automatically saved to your workstation:
    ${RESULTS_BASE}/dns-security-[timestamp]/
    ├── comprehensive_report.html    # Rich HTML report
    ├── results.json                # Raw test data
    ├── ci_variables.env            # CI/CD integration
    └── test_summary.json           # Pass/fail summary

EOF
}

print_banner() {
    cat << EOF
${CYAN}
╔══════════════════════════════════════════════════════════════════════════════╗
║                  DNS Security Testing Framework                              ║
║                         Production Mode                                      ║
╚══════════════════════════════════════════════════════════════════════════════╝
${NC}
EOF
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

validate_inventory() {
    local inventory_file="$1"

    if [[ ! -f "$inventory_file" ]]; then
        print_error "Inventory file not found: $inventory_file"
        print_info "Create an inventory file with your test hosts:"
        cat << EOF

[routers]
router1 ansible_host=192.168.1.1 ansible_user=admin

[servers]
server1 ansible_host=192.168.1.100 ansible_user=azazel

EOF
        return 1
    fi

    print_info "Validating inventory: $inventory_file"
    if ! ansible-inventory -i "$inventory_file" --list > /dev/null 2>&1; then
        print_error "Invalid inventory file format"
        return 1
    fi

    return 0
}

test_connectivity() {
    local inventory_file="$1"
    local limit_args="$2"

    print_info "Testing connectivity to target hosts..."

    local ping_cmd="ansible all -i '$inventory_file' -m ping $limit_args"
    if [[ -n "$VERBOSE" ]]; then
        ping_cmd="$ping_cmd $VERBOSE"
    fi

    if ! eval "$ping_cmd"; then
        print_warning "Some hosts are not reachable. Continue anyway? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_error "Connectivity test failed. Aborting."
            return 1
        fi
    else
        print_success "All target hosts are reachable"
    fi

    return 0
}

validate_tests_format() {
    local tests="$1"

    # Basic JSON validation
    if ! echo "$tests" | jq empty 2>/dev/null; then
        print_error "Invalid JSON format for tests: $tests"
        print_info "Example: '[\"baseline\",\"malicious_blocking\"]'"
        return 1
    fi

    # Check if it's an array
    if ! echo "$tests" | jq -e 'type == "array"' >/dev/null; then
        print_error "Tests must be a JSON array: $tests"
        return 1
    fi

    return 0
}

build_ansible_command() {
    local inventory_file="$1"
    local tests="$2"
    local environment="$3"

    local extra_vars="{\"dns_security_tests\":$tests,\"test_environment\":\"$environment\""
    extra_vars="$extra_vars,\"dns_controld_integration\":$CONTROLD_INTEGRATION"
    extra_vars="$extra_vars,\"dns_security_fail_on_critical\":$FAIL_ON_CRITICAL}"

    local ansible_cmd="ansible-playbook '$PLAYBOOK_PATH'"
    ansible_cmd="$ansible_cmd --extra-vars '$extra_vars'"
    ansible_cmd="$ansible_cmd -i '$inventory_file'"

    if [[ -n "$HOST_LIMIT" ]]; then
        ansible_cmd="$ansible_cmd --limit '$HOST_LIMIT'"
    fi

    if [[ -n "$VERBOSE" ]]; then
        ansible_cmd="$ansible_cmd $VERBOSE"
    fi

    if [[ -n "$CHECK_MODE" ]]; then
        ansible_cmd="$ansible_cmd --check --diff"
    fi

    echo "$ansible_cmd"
}

show_results() {
    print_success "DNS Security Testing completed!"
    echo

    # Find the most recent test session
    if [[ -d "$RESULTS_BASE" ]]; then
        local latest_session
        latest_session=$(find "$RESULTS_BASE" -type d -name "dns-security-*" | sort | tail -1)

        if [[ -n "$latest_session" && -d "$latest_session" ]]; then
            echo -e "${CYAN}📊 Test Results Available:${NC}"
            echo -e "   📁 Session Directory: $latest_session"

            if [[ -f "$latest_session/comprehensive_report.html" ]]; then
                echo -e "   🌐 HTML Report: $latest_session/comprehensive_report.html"
                print_info "Open HTML report: firefox '$latest_session/comprehensive_report.html'"
            fi

            if [[ -f "$latest_session/results.json" ]]; then
                echo -e "   📋 JSON Data: $latest_session/results.json"
                print_info "View JSON: cat '$latest_session/results.json' | jq ."
            fi

            if [[ -f "$latest_session/ci_variables.env" ]]; then
                echo -e "   🔧 CI Variables: $latest_session/ci_variables.env"
                print_info "Source variables: source '$latest_session/ci_variables.env'"
            fi

            # Show quick summary if available
            if [[ -f "$latest_session/results.json" ]]; then
                echo
                echo -e "${CYAN}📈 Quick Summary:${NC}"
                local success_rate
                success_rate=$(jq -r '.baseline_health.success_rate // "N/A"' "$latest_session/results.json" 2>/dev/null || echo "N/A")
                local threat_blocking
                threat_blocking=$(jq -r '.security_findings.malicious_blocking.effectiveness // "N/A"' "$latest_session/results.json" 2>/dev/null || echo "N/A")

                echo -e "   ✅ DNS Success Rate: ${success_rate}%"
                echo -e "   🛡️  Threat Blocking: ${threat_blocking}%"
            fi
        else
            print_warning "No recent test results found in $RESULTS_BASE"
        fi
    else
        print_warning "Results directory not found: $RESULTS_BASE"
    fi
}

main() {
    local inventory_file=""
    local tests="$DEFAULT_TESTS"
    local environment="$DEFAULT_ENVIRONMENT"

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -i|--inventory)
                inventory_file="$2"
                shift 2
                ;;
            -l|--limit)
                HOST_LIMIT="$2"
                shift 2
                ;;
            -t|--tests)
                tests="$2"
                shift 2
                ;;
            -e|--environment)
                environment="$2"
                shift 2
                ;;
            -c|--controld)
                CONTROLD_INTEGRATION=true
                shift
                ;;
            -f|--fail-critical)
                FAIL_ON_CRITICAL=true
                shift
                ;;
            -v|--verbose)
                if [[ "$VERBOSE" == "" ]]; then
                    VERBOSE="-v"
                elif [[ "$VERBOSE" == "-v" ]]; then
                    VERBOSE="-vv"
                elif [[ "$VERBOSE" == "-vv" ]]; then
                    VERBOSE="-vvv"
                fi
                shift
                ;;
            --check)
                CHECK_MODE="--check"
                shift
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$inventory_file" ]]; then
        print_error "Inventory file is required"
        print_usage
        exit 1
    fi

    print_banner

    # Validate inputs
    if ! validate_inventory "$inventory_file"; then
        exit 1
    fi

    if ! validate_tests_format "$tests"; then
        exit 1
    fi

    # Check for required tools
    for tool in ansible-playbook jq; do
        if ! command -v "$tool" > /dev/null; then
            print_error "Required tool not found: $tool"
            exit 1
        fi
    done

    # Build limit arguments for ansible commands
    local limit_args=""
    if [[ -n "$HOST_LIMIT" ]]; then
        limit_args="--limit '$HOST_LIMIT'"
    fi

    # Test connectivity
    if ! test_connectivity "$inventory_file" "$limit_args"; then
        exit 1
    fi

    # Show configuration
    echo -e "${CYAN}🔧 Test Configuration:${NC}"
    echo -e "   📂 Inventory: $inventory_file"
    echo -e "   🎯 Tests: $tests"
    echo -e "   🏷️  Environment: $environment"
    echo -e "   🔗 Control D: $CONTROLD_INTEGRATION"
    echo -e "   ❌ Fail on Critical: $FAIL_ON_CRITICAL"
    if [[ -n "$HOST_LIMIT" ]]; then
        echo -e "   🎯 Host Limit: $HOST_LIMIT"
    fi
    if [[ -n "$CHECK_MODE" ]]; then
        echo -e "   🔍 Check Mode: Enabled"
    fi
    echo

    # Build and execute ansible command
    local ansible_cmd
    ansible_cmd=$(build_ansible_command "$inventory_file" "$tests" "$environment")

    print_info "Executing: $ansible_cmd"
    echo

    # Execute the playbook
    if eval "$ansible_cmd"; then
        echo
        show_results
        print_success "DNS security testing completed successfully!"
        exit 0
    else
        print_error "DNS security testing failed"
        echo
        print_info "Check the output above for details"
        print_info "Add -v for more verbose output"
        exit 1
    fi
}

# Run main function
main "$@"
