#!/usr/bin/env bash
# DNS Security Testing Framework Demonstration Script
# Showcases the comprehensive DNS security testing capabilities of Gutter Bonez
# Designed for Azazel's QA testing infrastructure

set -euo pipefail

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
INVENTORY_FILE="${PROJECT_ROOT}/inventory/example_dns_security.yml"
DEMO_INVENTORY_FILE="/tmp/gutter_bonez_demo_inventory.yml"
DEMO_LOG_FILE="/tmp/gutter_bonez_dns_security_demo.log"

# Detect terminal capabilities and set colors
if [[ -t 1 ]] && command -v tput &> /dev/null && tput colors &> /dev/null && [[ $(tput colors) -ge 8 ]]; then
    # Terminal supports colors
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    PURPLE=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    WHITE=$(tput bold; tput setaf 7)
    NC=$(tput sgr0) # No Color
else
    # No color support - use plain text
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    PURPLE=''
    CYAN=''
    WHITE=''
    NC=''
fi

# Demo banner
print_banner() {
    if [[ -n "$WHITE" ]]; then
        # Color banner
        echo "${WHITE}"
        cat << 'EOF'
🦴━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━🦴
                    GUTTER BONEZ DNS SECURITY TESTING DEMO

                      Comprehensive DNS Infrastructure Security
                           Testing & Threat Detection Framework
🦴━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━🦴
EOF
        echo "${NC}"
    else
        # Plain text banner
        cat << 'EOF'
===============================================================================
                    GUTTER BONEZ DNS SECURITY TESTING DEMO

                      Comprehensive DNS Infrastructure Security
                           Testing & Threat Detection Framework
===============================================================================
EOF
    fi
}

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$DEMO_LOG_FILE"
}

# Colored output functions
print_step() {
    echo "${CYAN}🔧 $1${NC}"
    log "STEP: $1"
}

print_info() {
    echo "${BLUE}ℹ️  $1${NC}"
    log "INFO: $1"
}

print_success() {
    echo "${GREEN}✅ $1${NC}"
    log "SUCCESS: $1"
}

print_warning() {
    echo "${YELLOW}⚠️  $1${NC}"
    log "WARNING: $1"
}

print_error() {
    echo "${RED}❌ $1${NC}"
    log "ERROR: $1"
}

print_header() {
    echo ""
    if [[ -n "$WHITE" ]]; then
        echo "${WHITE}━━━ $1 ━━━${NC}"
    else
        echo "=== $1 ==="
    fi
    echo ""
    log "HEADER: $1"
}

# Create demo inventory for localhost testing
create_demo_inventory() {
    cat > "$DEMO_INVENTORY_FILE" << 'EOF'
---
all:
  hosts:
    localhost:
      ansible_connection: local
      ansible_become: false
      dns_security_tests:
        - "baseline"
        - "malicious_blocking"
        - "performance"
      dns_controld_integration: false
      test_environment: "demo"
      dns_security_fail_on_critical: false
  vars:
    dns_security_global:
      parallel_testing: false
      test_timeout: 60
      cleanup_on_failure: true
      generate_artifacts: true
      fail_fast: false
EOF
    print_info "Created demo inventory: $DEMO_INVENTORY_FILE"
}

# Check prerequisites
check_prerequisites() {
    print_header "Prerequisites Check"

    local missing_tools=()

    # Check for required tools
    for tool in ansible ansible-playbook dig curl openssl; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        else
            print_success "$tool is available"
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Please install missing tools before running the demo"
        return 1
    fi

    # Check Ansible version
    local ansible_version
    ansible_version=$(ansible --version | head -1 | grep -oE '[0-9]+\.[0-9]+')
    print_info "Ansible version: $ansible_version"

    # Check if we're in the right directory
    if [[ ! -f "${PROJECT_ROOT}/playbooks/dns_security_testing.yml" ]]; then
        print_error "DNS security testing playbook not found!"
        print_info "Make sure you're running this script from the gutter_bonez project"
        return 1
    fi

    print_success "All prerequisites satisfied"
}

# Display demo menu
show_demo_menu() {
    print_header "DNS Security Testing Demo Options"

    cat << EOF
${WHITE}Available Demo Scenarios:${NC}

${GREEN}1.${NC} ${CYAN}Basic DNS Health Check${NC}
   - DNS resolution baseline testing
   - Response time analysis
   - Success rate validation

${GREEN}2.${NC} ${CYAN}Malicious Domain Blocking Test${NC}
   - Test DNS filtering effectiveness
   - Category-based threat detection
   - Policy enforcement validation

${GREEN}3.${NC} ${CYAN}HTTPS Interception Detection${NC}
   - Certificate chain analysis
   - Man-in-the-middle detection
   - Corporate proxy identification

${GREEN}4.${NC} ${CYAN}Captive Portal Detection${NC}
   - Network authentication testing
   - Connectivity check validation
   - Public WiFi analysis

${GREEN}5.${NC} ${CYAN}DNS-over-HTTPS (DoH) Testing${NC}
   - Secure DNS protocol validation
   - DoH provider testing
   - Encrypted DNS functionality

${GREEN}6.${NC} ${CYAN}Control D Integration Test${NC}
   - ctrld service validation
   - Policy enforcement testing
   - verify.controld.com integration

${GREEN}7.${NC} ${CYAN}Comprehensive Security Audit${NC}
   - Full security testing suite
   - Performance benchmarking
   - Complete threat analysis

${GREEN}8.${NC} ${CYAN}Custom Test Configuration${NC}
   - Interactive test selection
   - Custom parameter configuration
   - Advanced testing options

${GREEN}9.${NC} ${CYAN}View Previous Test Results${NC}
   - Browse test history
   - Generate comparison reports
   - Analyze trends

${GREEN}T.${NC} ${PURPLE}Test Terminal Colors${NC}
   - Check color support
   - Terminal diagnostics
   - Display test

${GREEN}0.${NC} ${RED}Exit Demo${NC}

EOF
}

# Basic DNS health check demo
demo_basic_health_check() {
    print_header "Basic DNS Health Check Demo"

    print_step "Creating demo inventory for localhost testing..."
    create_demo_inventory

    print_step "Running DNS baseline health assessment..."

    local test_cmd="ansible-playbook ${PROJECT_ROOT}/playbooks/dns_security_testing.yml"
    test_cmd+=" --extra-vars 'dns_security_tests=[\"baseline\"] test_environment=demo'"
    test_cmd+=" --extra-vars 'dns_security_fail_on_critical=false dns_controld_integration=false'"
    test_cmd+=" -i ${DEMO_INVENTORY_FILE}"

    print_info "Command: $test_cmd"

    if eval "$test_cmd"; then
        print_success "DNS health check completed successfully"
        show_test_results "baseline"
    else
        print_error "DNS health check failed"
        return 1
    fi
}

# Malicious domain blocking test demo
demo_malicious_blocking() {
    print_header "Malicious Domain Blocking Test Demo"

    create_demo_inventory
    print_step "Testing DNS filtering and threat protection..."

    local test_cmd="ansible-playbook ${PROJECT_ROOT}/playbooks/dns_security_testing.yml"
    test_cmd+=" --extra-vars 'dns_security_tests=[\"malicious_blocking\"] test_environment=demo'"
    test_cmd+=" --extra-vars 'dns_controld_integration=false'"
    test_cmd+=" -i ${DEMO_INVENTORY_FILE}"

    print_info "Testing malicious domains: ads.testcategory.com, malware.testcategory.com, phishing.testcategory.com"

    if eval "$test_cmd"; then
        print_success "Malicious domain blocking test completed"
        show_test_results "malicious_blocking"
    else
        print_warning "Some malicious domains may not be properly blocked"
        show_test_results "malicious_blocking"
    fi
}

# HTTPS interception detection demo
demo_https_interception() {
    print_header "HTTPS Interception Detection Demo"

    create_demo_inventory
    print_step "Analyzing certificate chains for interception..."

    local test_cmd="ansible-playbook ${PROJECT_ROOT}/playbooks/dns_security_testing.yml"
    test_cmd+=" --extra-vars 'dns_security_tests=[\"https_interception\"] test_environment=demo'"
    test_cmd+=" --extra-vars 'dns_controld_integration=false'"
    test_cmd+=" -i ${DEMO_INVENTORY_FILE}"

    print_info "Checking certificates for: google.com, github.com, cloudflare.com"

    if eval "$test_cmd"; then
        print_success "HTTPS interception detection completed"
        show_test_results "https_interception"
    else
        print_error "HTTPS interception detection failed"
        return 1
    fi
}

# Captive portal detection demo
demo_captive_portal() {
    print_header "Captive Portal Detection Demo"

    create_demo_inventory
    print_step "Testing for captive portal presence..."

    local test_cmd="ansible-playbook ${PROJECT_ROOT}/playbooks/dns_security_testing.yml"
    test_cmd+=" --extra-vars 'dns_security_tests=[\"captive_portal\"] test_environment=demo'"
    test_cmd+=" --extra-vars 'dns_controld_integration=false'"
    test_cmd+=" -i ${DEMO_INVENTORY_FILE}"

    print_info "Testing connectivity to: detectportal.firefox.com, connectivitycheck.gstatic.com"

    if eval "$test_cmd"; then
        print_success "Captive portal detection completed"
        show_test_results "captive_portal"
    else
        print_error "Captive portal detection failed"
        return 1
    fi
}

# DoH testing demo
demo_doh_testing() {
    print_header "DNS-over-HTTPS (DoH) Testing Demo"

    create_demo_inventory
    print_step "Testing secure DNS protocols..."

    local test_cmd="ansible-playbook ${PROJECT_ROOT}/playbooks/dns_security_testing.yml"
    test_cmd+=" --extra-vars 'dns_security_tests=[\"secure_dns\"] test_environment=demo'"
    test_cmd+=" --extra-vars 'dns_controld_integration=false'"
    test_cmd+=" -i ${DEMO_INVENTORY_FILE}"

    print_info "Testing DoH providers: Cloudflare, Google, Quad9"

    if eval "$test_cmd"; then
        print_success "DoH testing completed"
        show_test_results "secure_dns"
    else
        print_warning "Some DoH providers may be unavailable"
        show_test_results "secure_dns"
    fi
}

# Control D integration demo
demo_controld_integration() {
    print_header "Control D Integration Test Demo"

    create_demo_inventory
    print_step "Testing Control D service integration..."

    local test_cmd="ansible-playbook ${PROJECT_ROOT}/playbooks/dns_security_testing.yml"
    test_cmd+=" --extra-vars 'dns_security_tests=[\"baseline\",\"malicious_blocking\"] test_environment=demo'"
    test_cmd+=" --extra-vars 'dns_controld_integration=true'"
    test_cmd+=" -i ${DEMO_INVENTORY_FILE}"

    print_info "Validating: verify.controld.com, ctrld service status, policy enforcement"

    if eval "$test_cmd"; then
        print_success "Control D integration test completed"
        show_test_results "controld_integration"
    else
        print_warning "Control D service may not be properly configured"
        show_test_results "controld_integration"
    fi
}

# Comprehensive security audit demo
demo_comprehensive_audit() {
    print_header "Comprehensive Security Audit Demo"

    create_demo_inventory
    print_step "Running complete DNS security assessment..."
    print_warning "This may take 5-10 minutes to complete"

    local test_cmd="ansible-playbook ${PROJECT_ROOT}/playbooks/dns_security_testing.yml"
    test_cmd+=" --extra-vars 'test_environment=demo dns_controld_integration=false'"
    test_cmd+=" -i ${DEMO_INVENTORY_FILE}"

    print_info "Running all security tests: baseline, malicious blocking, HTTPS interception, performance"

    if eval "$test_cmd"; then
        print_success "Comprehensive security audit completed"
        show_comprehensive_results
    else
        print_error "Security audit encountered issues"
        show_comprehensive_results
    fi
}

# Custom test configuration
demo_custom_configuration() {
    print_header "Custom Test Configuration"

    echo "${WHITE}Select test categories (space-separated numbers):${NC}"
    echo "1) baseline  2) malicious_blocking  3) https_interception"
    echo "4) captive_portal  5) secure_dns  6) performance"

    read -p "Enter your selection: " -r test_selection

    local test_categories=()
    for selection in $test_selection; do
        case $selection in
            1) test_categories+=("baseline") ;;
            2) test_categories+=("malicious_blocking") ;;
            3) test_categories+=("https_interception") ;;
            4) test_categories+=("captive_portal") ;;
            5) test_categories+=("secure_dns") ;;
            6) test_categories+=("performance") ;;
            *) print_warning "Invalid selection: $selection" ;;
        esac
    done

    if [[ ${#test_categories[@]} -eq 0 ]]; then
        print_error "No valid test categories selected"
        return 1
    fi

    # Convert array to JSON format
    local categories_json
    categories_json=$(printf '"%s",' "${test_categories[@]}")
    categories_json="[${categories_json%,}]"

    print_step "Running custom test configuration..."
    print_info "Selected categories: ${test_categories[*]}"

    create_demo_inventory
    local test_cmd="ansible-playbook ${PROJECT_ROOT}/playbooks/dns_security_testing.yml"
    test_cmd+=" --extra-vars 'dns_security_tests=${categories_json} test_environment=demo'"
    test_cmd+=" --extra-vars 'dns_controld_integration=false'"
    test_cmd+=" -i ${DEMO_INVENTORY_FILE}"

    if eval "$test_cmd"; then
        print_success "Custom test configuration completed"
        show_test_results "custom"
    else
        print_error "Custom test configuration failed"
        return 1
    fi
}

# Show test results
show_test_results() {
    local test_type="$1"

    print_header "Test Results - $test_type"

    # Find the most recent test results
    local latest_result
    latest_result=$(find /tmp/gutter_bonez_dns_security -name "results.json" -type f -exec ls -t {} + | head -1 2>/dev/null || echo "")

    if [[ -n "$latest_result" && -f "$latest_result" ]]; then
        print_info "Latest test results: $latest_result"

        # Extract key metrics using jq if available
        if command -v jq &> /dev/null; then
            echo ""
            echo "${WHITE}Key Metrics:${NC}"
            jq -r '
                if .security_summary then
                    "• DNS Success Rate: " + (.security_summary.baseline_health.success_rate // "N/A" | tostring) + "%",
                    "• Threat Blocking: " + (.security_summary.security_findings.malicious_blocking.effectiveness // "N/A" | tostring) + "%",
                    "• Avg Response Time: " + (.security_summary.performance_metrics.average_response_time // "N/A" | tostring) + "ms",
                    "• HTTPS Interception: " + (if .security_summary.security_findings.https_security.interception_detected then "DETECTED" else "NOT DETECTED" end)
                else
                    "Test results format not recognized"
                end' "$latest_result" 2>/dev/null || print_warning "Could not parse JSON results"
        fi

        # Show HTML report location
        local html_report
        html_report=$(dirname "$latest_result")/comprehensive_report.html
        if [[ -f "$html_report" ]]; then
            print_success "Interactive HTML report available: $html_report"
            print_info "Open in browser: file://$html_report"
        fi

    else
        print_warning "No test results found in /tmp/gutter_bonez_dns_security/"
    fi

    echo ""
    read -p "Press Enter to continue..."
}

# Show comprehensive results
show_comprehensive_results() {
    show_test_results "comprehensive"

    # Additional comprehensive analysis
    print_header "Security Assessment Summary"

    local results_dir="/tmp/gutter_bonez_dns_security"
    if [[ -d "$results_dir" ]]; then
        local latest_session
        latest_session=$(find "$results_dir" -maxdepth 1 -type d -name "dns-sec-*" | sort -r | head -1)

        if [[ -n "$latest_session" ]]; then
            print_info "Full results directory: $latest_session"

            # List available reports
            echo ""
            echo "${WHITE}Available Reports:${NC}"
            find "$latest_session" -name "*.html" -exec basename {} \; | while read -r report; do
                echo "• $report"
            done

            find "$latest_session" -name "*.json" -exec basename {} \; | while read -r report; do
                echo "• $report"
            done
        fi
    fi
}

# View previous test results
view_previous_results() {
    print_header "Previous Test Results Browser"

    local results_base="/tmp/gutter_bonez_dns_security"

    if [[ ! -d "$results_base" ]]; then
        print_warning "No previous test results found"
        return
    fi

    local sessions
    mapfile -t sessions < <(find "$results_base" -maxdepth 1 -type d -name "dns-sec-*" | sort -r)

    if [[ ${#sessions[@]} -eq 0 ]]; then
        print_warning "No test sessions found"
        return
    fi

    echo "${WHITE}Available Test Sessions:${NC}"
    local i=1
    for session in "${sessions[@]}"; do
        local session_name
        session_name=$(basename "$session")
        local session_time
        session_time=$(date -d "@${session_name#dns-sec-}" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "Unknown time")
        echo "$i) $session_name ($session_time)"
        ((i++))
    done

    echo "0) Return to main menu"

    read -p "Select a session to view: " -r selection

    if [[ "$selection" == "0" ]]; then
        return
    elif [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -le "${#sessions[@]}" ]] && [[ "$selection" -gt 0 ]]; then
        local selected_session="${sessions[$((selection-1))]}"

        print_info "Viewing session: $(basename "$selected_session")"

        # Show session contents
        echo ""
        echo "${WHITE}Session Contents:${NC}"
        find "$selected_session" -type f | while read -r file; do
            local filename
            filename=$(basename "$file")
            local filesize
            filesize=$(du -h "$file" | cut -f1)
            echo "• $filename ($filesize)"
        done

        # Open HTML report if available
        local html_report="$selected_session/comprehensive_report.html"
        if [[ -f "$html_report" ]]; then
            print_success "HTML report found: $html_report"
            read -p "Open HTML report in browser? (y/N): " -r open_browser
            if [[ "$open_browser" =~ ^[Yy]$ ]]; then
                if command -v xdg-open &> /dev/null; then
                    xdg-open "file://$html_report"
                elif command -v open &> /dev/null; then
                    open "file://$html_report"
                else
                    print_info "Manual open: file://$html_report"
                fi
            fi
        fi

        echo ""
        read -p "Press Enter to continue..."
    else
        print_error "Invalid selection"
    fi
}

# Main demo loop
main_demo_loop() {
    while true; do
        clear
        print_banner
        show_demo_menu

        read -p "Select demo option (0-9, T): " -r choice

        case $choice in
            1) demo_basic_health_check ;;
            2) demo_malicious_blocking ;;
            3) demo_https_interception ;;
            4) demo_captive_portal ;;
            5) demo_doh_testing ;;
            6) demo_controld_integration ;;
            7) demo_comprehensive_audit ;;
            8) demo_custom_configuration ;;
            9) view_previous_results ;;
            [Tt]) test_colors ;;
            0)
                print_info "Exiting DNS Security Testing Demo"
                print_success "Thank you for exploring Gutter Bonez DNS Security Framework!"
                break
                ;;
            *)
                print_error "Invalid option. Please select 0-9 or T."
                sleep 2
                ;;
        esac
    done
}

# Script usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

DNS Security Testing Framework Demo Script

OPTIONS:
    -h, --help              Show this help message
    -c, --check             Check prerequisites only
    -q, --quick             Run quick demo (basic health check)
    -f, --full              Run comprehensive security audit
    -l, --list-results      List previous test results
    --inventory FILE        Use custom inventory file
    --log-level LEVEL       Set logging level (debug, info, warning, error)
    --no-color              Disable color output (plain text mode)
    --test-colors           Test terminal color support

EXAMPLES:
    $0                      # Interactive demo menu
    $0 --quick              # Quick DNS health check
    $0 --full               # Comprehensive security audit
    $0 --check              # Prerequisites check only
    $0 --test-colors        # Test terminal color support
    $0 --no-color           # Force plain text mode

For more information, see: docs/DNS_SECURITY_TESTING.md
EOF
}

# Color test function
test_colors() {
    print_header "Terminal Color Support Test"

    echo "Testing color output:"
    print_step "This is a step message"
    print_info "This is an info message"
    print_success "This is a success message"
    print_warning "This is a warning message"
    print_error "This is an error message"

    echo ""
    echo "Terminal info:"
    echo "• TERM: ${TERM:-not set}"
    echo "• Colors supported: $(tput colors 2>/dev/null || echo 'unknown')"
    echo "• Is TTY: $([[ -t 1 ]] && echo 'yes' || echo 'no')"

    if [[ -n "$RED" ]]; then
        echo "• Color mode: ENABLED"
    else
        echo "• Color mode: DISABLED (plain text)"
    fi

    echo ""
    read -p "Press Enter to continue..."
}

# Handle command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -c|--check)
            check_prerequisites
            exit $?
            ;;
        -q|--quick)
            check_prerequisites && demo_basic_health_check
            exit $?
            ;;
        -f|--full)
            check_prerequisites && demo_comprehensive_audit
            exit $?
            ;;
        -l|--list-results)
            view_previous_results
            exit 0
            ;;
        --no-color)
            # Force disable colors
            RED=''
            GREEN=''
            YELLOW=''
            BLUE=''
            PURPLE=''
            CYAN=''
            WHITE=''
            NC=''
            shift
            ;;
        --test-colors)
            test_colors
            exit 0
            ;;
        --inventory)
            INVENTORY_FILE="$2"
            shift 2
            ;;
        --log-level)
            export ANSIBLE_VERBOSITY="$2"
            shift 2
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    # Initialize log file
    > "$DEMO_LOG_FILE"

    print_info "Demo log file: $DEMO_LOG_FILE"

    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi

    # Start main demo loop
    main_demo_loop

    # Cleanup demo inventory file
    [[ -f "$DEMO_INVENTORY_FILE" ]] && rm -f "$DEMO_INVENTORY_FILE"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
