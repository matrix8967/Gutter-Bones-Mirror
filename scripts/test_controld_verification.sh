#!/bin/bash

# ====================
# CONTROL D VERIFICATION TEST SCRIPT
# ====================
# Tests Control D verification response parsing
# Author: Azazel (QA & Support Engineer)
# Version: 1.0

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONTROLD_URL="https://verify.controld.com"
TEMP_DIR="/tmp/controld_test"

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

# Help function
show_help() {
    cat << EOF
🔍 Control D Verification Test Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Verbose output
    -d, --debug         Debug mode with detailed output
    -t, --timeout N     Set timeout for requests (default: 15)
    -o, --output FILE   Save response to file
    --no-color          Disable colored output
    --test-parsing      Test parsing with sample data
    --fix-playbook      Generate fixed playbook snippet

DESCRIPTION:
    This script tests Control D verification response parsing to help
    debug issues with the DNS security testing playbook.

    It will:
    • Test connectivity to verify.controld.com
    • Analyze the response format
    • Test regex patterns used in playbooks
    • Provide fixes for parsing issues

EXAMPLES:
    # Basic test
    $0

    # Verbose test with debugging
    $0 --debug --verbose

    # Test with custom timeout
    $0 --timeout 30

    # Generate playbook fix
    $0 --fix-playbook

EOF
}

# Create temp directory
setup_temp_dir() {
    mkdir -p "$TEMP_DIR"
}

# Clean up temp directory
cleanup() {
    rm -rf "$TEMP_DIR"
}

# Test Control D connectivity
test_connectivity() {
    log_header "🌐 Testing Control D Connectivity"

    local timeout="${TIMEOUT:-15}"
    local response_file="$TEMP_DIR/controld_response.html"
    local headers_file="$TEMP_DIR/controld_headers.txt"

    log_info "Testing connectivity to $CONTROLD_URL..."

    # Test with curl
    if curl -s -m "$timeout" -D "$headers_file" -o "$response_file" "$CONTROLD_URL"; then
        local status_code=$(grep -E "^HTTP" "$headers_file" | tail -1 | awk '{print $2}')
        local content_length=$(wc -c < "$response_file")

        log_success "Connection successful!"
        log_info "Status Code: $status_code"
        log_info "Content Length: $content_length bytes"

        # Show headers if debug mode
        if [[ "${DEBUG:-false}" == "true" ]]; then
            log_info "Response Headers:"
            cat "$headers_file" | sed 's/^/  /'
        fi

        return 0
    else
        log_error "Failed to connect to $CONTROLD_URL"
        log_warning "This could be because:"
        log_warning "  • Not connected to Control D network"
        log_warning "  • Network connectivity issues"
        log_warning "  • Control D service unavailable"
        return 1
    fi
}

# Analyze response content
analyze_response() {
    log_header "🔍 Analyzing Control D Response"

    local response_file="$TEMP_DIR/controld_response.html"

    if [[ ! -f "$response_file" ]]; then
        log_error "No response file found. Run connectivity test first."
        return 1
    fi

    local content_length=$(wc -c < "$response_file")
    local line_count=$(wc -l < "$response_file")

    log_info "Response Analysis:"
    log_info "  Content Length: $content_length bytes"
    log_info "  Line Count: $line_count lines"

    # Show first 20 lines
    log_info "First 20 lines of response:"
    head -20 "$response_file" | sed 's/^/  /'

    echo ""

    # Check for common Control D patterns
    log_info "Checking for Control D patterns..."

    local patterns=(
        "DNS Server:"
        "Location:"
        "Resolver IP:"
        "Filtering:"
        "Control"
        "controld"
        "resolver"
        "IP Address"
    )

    local found_patterns=()

    for pattern in "${patterns[@]}"; do
        if grep -iq "$pattern" "$response_file"; then
            log_success "Found pattern: '$pattern'"
            found_patterns+=("$pattern")

            # Show the matching lines
            if [[ "${VERBOSE:-false}" == "true" ]]; then
                log_info "  Matching lines:"
                grep -i "$pattern" "$response_file" | sed 's/^/    /'
            fi
        else
            log_warning "Pattern not found: '$pattern'"
        fi
    done

    if [[ ${#found_patterns[@]} -eq 0 ]]; then
        log_warning "No Control D-specific patterns found"
        log_info "This suggests either:"
        log_info "  • Not connected to Control D"
        log_info "  • Control D response format has changed"
        log_info "  • Different verification page format"
    else
        log_success "Found ${#found_patterns[@]} Control D patterns"
    fi

    return 0
}

# Test regex patterns
test_regex_patterns() {
    log_header "🧪 Testing Regex Patterns"

    local response_file="$TEMP_DIR/controld_response.html"

    if [[ ! -f "$response_file" ]]; then
        log_error "No response file found. Run connectivity test first."
        return 1
    fi

    # Test the exact patterns used in the playbook
    local patterns=(
        "DNS Server: ([0-9.]+)"
        "Location: ([^\\n\\r]+)"
        "Resolver IP: ([0-9.]+)"
        "Filtering: ([^\\n\\r]+)"
    )

    log_info "Testing playbook regex patterns..."

    for pattern in "${patterns[@]}"; do
        log_info "Testing pattern: $pattern"

        if grep -Eo "$pattern" "$response_file" >/dev/null; then
            log_success "  Pattern matches!"

            # Show what it matched
            local matches=$(grep -Eo "$pattern" "$response_file")
            log_info "  Matches:"
            echo "$matches" | sed 's/^/    /'

            # Test extraction (like Ansible would do)
            local extracted=$(grep -Eo "$pattern" "$response_file" | sed -E "s/$pattern/\\1/" | head -1)
            log_info "  Extracted value: '$extracted'"
        else
            log_warning "  Pattern does not match"
        fi
        echo ""
    done
}

# Test with sample Control D data
test_with_sample_data() {
    log_header "🎯 Testing with Sample Control D Data"

    local sample_file="$TEMP_DIR/sample_controld.html"

    # Create sample Control D response
    cat > "$sample_file" << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Control D Verification</title></head>
<body>
<h1>DNS Verification</h1>
<p>DNS Server: 76.76.19.19</p>
<p>Location: United States</p>
<p>Resolver IP: 192.168.1.1</p>
<p>Filtering: Active</p>
<p>Status: Connected to Control D</p>
</body>
</html>
EOF

    log_info "Testing with sample Control D response..."

    # Test patterns against sample data
    local patterns=(
        "DNS Server: ([0-9.]+)"
        "Location: ([^\\n\\r]+)"
        "Resolver IP: ([0-9.]+)"
        "Filtering: ([^\\n\\r]+)"
    )

    for pattern in "${patterns[@]}"; do
        log_info "Pattern: $pattern"

        if grep -Eo "$pattern" "$sample_file" >/dev/null; then
            local extracted=$(grep -Eo "$pattern" "$sample_file" | sed -E "s/.*$pattern.*/\\1/" | head -1)
            log_success "  Extracted: '$extracted'"
        else
            log_error "  No match"
        fi
    done
}

# Generate playbook fix
generate_playbook_fix() {
    log_header "🔧 Generating Playbook Fix"

    local fix_file="$TEMP_DIR/playbook_fix.yml"

    cat > "$fix_file" << 'EOF'
# ====================
# FIXED CONTROL D PARSING
# ====================
# Replace the problematic parsing section with this:

        - name: Parse Control D verification details (FIXED)
          block:
            # First, safely extract matches into lists
            - name: Extract Control D data with regex_findall
              set_fact:
                controld_matches:
                  dns_server: "{{ controld_comprehensive_test.content | default('') | regex_findall('DNS Server: ([0-9.]+)') }}"
                  location: "{{ controld_comprehensive_test.content | default('') | regex_findall('Location: ([^\\n\\r]+)') }}"
                  resolver_ip: "{{ controld_comprehensive_test.content | default('') | regex_findall('Resolver IP: ([0-9.]+)') }}"
                  filtering_status: "{{ controld_comprehensive_test.content | default('') | regex_findall('Filtering: ([^\\n\\r]+)') }}"

            # Then safely get first match or default
            - name: Set Control D verification details
              set_fact:
                controld_verification:
                  accessible: "{{ controld_comprehensive_test.status | default(0) == 200 }}"
                  response_time: "{{ controld_comprehensive_test.elapsed | default(0) }}"
                  dns_server: "{{ controld_matches.dns_server[0] | default('not_detected') }}"
                  location: "{{ controld_matches.location[0] | default('not_detected') }}"
                  resolver_ip: "{{ controld_matches.resolver_ip[0] | default('not_detected') }}"
                  filtering_status: "{{ controld_matches.filtering_status[0] | default('not_detected') }}"
                  service_detected: "{{ controld_comprehensive_test.content | default('') | regex_search('Control', ignorecase=true) is not none }}"
          when:
            - dns_controld_integration
            - controld_comprehensive_test is defined

# Alternative simpler approach:
        - name: Parse Control D verification details (SIMPLE)
          set_fact:
            controld_verification:
              accessible: "{{ controld_comprehensive_test.status | default(0) == 200 }}"
              response_time: "{{ controld_comprehensive_test.elapsed | default(0) }}"
              dns_server: "{{ controld_comprehensive_test.content | default('') | regex_replace('.*DNS Server: ([0-9.]+).*', '\\1') if (controld_comprehensive_test.content | default('') | regex_search('DNS Server: ([0-9.]+)')) else 'not_detected' }}"
              location: "{{ controld_comprehensive_test.content | default('') | regex_replace('.*Location: ([^\\n\\r]+).*', '\\1') if (controld_comprehensive_test.content | default('') | regex_search('Location: ([^\\n\\r]+)')) else 'not_detected' }}"
              has_controld_content: "{{ 'Control' in (controld_comprehensive_test.content | default('')) }}"
          when:
            - dns_controld_integration
            - controld_comprehensive_test is defined
EOF

    log_success "Playbook fix generated: $fix_file"
    log_info "Copy the content above to replace the problematic parsing section"

    if [[ "${VERBOSE:-false}" == "true" ]]; then
        echo ""
        log_info "Generated fix content:"
        cat "$fix_file" | sed 's/^/  /'
    fi
}

# Generate debug playbook
generate_debug_playbook() {
    local debug_file="$TEMP_DIR/debug_controld.yml"

    cat > "$debug_file" << 'EOF'
---
# Control D Debug Playbook
- name: Debug Control D Verification
  hosts: localhost
  gather_facts: no
  tasks:
    - name: Test Control D verification
      uri:
        url: "https://verify.controld.com"
        method: GET
        timeout: 15
        return_content: yes
      register: controld_test
      failed_when: false

    - name: Show raw response
      debug:
        msg: |
          Status: {{ controld_test.status | default('no_status') }}
          Content: {{ controld_test.content | default('no_content') }}

    - name: Test parsing patterns
      debug:
        msg: |
          DNS Server matches: {{ controld_test.content | default('') | regex_findall('DNS Server: ([0-9.]+)') }}
          Location matches: {{ controld_test.content | default('') | regex_findall('Location: ([^\\n\\r]+)') }}
          Resolver matches: {{ controld_test.content | default('') | regex_findall('Resolver IP: ([0-9.]+)') }}
          Filtering matches: {{ controld_test.content | default('') | regex_findall('Filtering: ([^\\n\\r]+)') }}
EOF

    log_info "Debug playbook generated: $debug_file"
    log_info "Run with: ansible-playbook $debug_file"
}

# Main function
main() {
    local timeout=15
    local verbose=false
    local debug=false
    local test_parsing=false
    local fix_playbook=false
    local output_file=""

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -d|--debug)
                debug=true
                verbose=true
                shift
                ;;
            -t|--timeout)
                timeout="$2"
                shift 2
                ;;
            -o|--output)
                output_file="$2"
                shift 2
                ;;
            --no-color)
                RED=''
                GREEN=''
                YELLOW=''
                BLUE=''
                CYAN=''
                NC=''
                shift
                ;;
            --test-parsing)
                test_parsing=true
                shift
                ;;
            --fix-playbook)
                fix_playbook=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Set global variables
    export VERBOSE=$verbose
    export DEBUG=$debug
    export TIMEOUT=$timeout

    # Setup
    setup_temp_dir
    trap cleanup EXIT

    log_header "🔍 Control D Verification Test"
    log_info "Testing Control D verification parsing issues"
    echo ""

    # Execute tests based on options
    if [[ "$test_parsing" == "true" ]]; then
        test_with_sample_data
    elif [[ "$fix_playbook" == "true" ]]; then
        generate_playbook_fix
        generate_debug_playbook
    else
        # Full test sequence
        if test_connectivity; then
            analyze_response
            test_regex_patterns
        else
            log_warning "Connectivity test failed, testing with sample data instead..."
            test_with_sample_data
        fi

        generate_playbook_fix
    fi

    # Save output if requested
    if [[ -n "$output_file" ]] && [[ -f "$TEMP_DIR/controld_response.html" ]]; then
        cp "$TEMP_DIR/controld_response.html" "$output_file"
        log_success "Response saved to: $output_file"
    fi

    log_header "✅ Test Complete"
    log_info "Generated files in: $TEMP_DIR"
    log_info "Use --fix-playbook to get the corrected playbook syntax"
}

# Run main function
main "$@"
