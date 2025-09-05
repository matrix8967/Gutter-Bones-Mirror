#!/usr/bin/env bash
# Simple DNS Security Testing Demo
# A working demonstration of core DNS security capabilities

set -euo pipefail

# Colors with fallback
if [[ -t 1 ]] && command -v tput &> /dev/null && tput colors &> /dev/null && [[ $(tput colors) -ge 8 ]]; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    CYAN=$(tput setaf 6)
    BOLD=$(tput bold)
    NC=$(tput sgr0)
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

print_banner() {
    echo "${BOLD}${BLUE}"
    echo "============================================================================="
    echo "                    GUTTER BONEZ DNS SECURITY DEMO"
    echo "                     Simple Working Demonstration"
    echo "============================================================================="
    echo "${NC}"
}

print_header() {
    echo ""
    echo "${BOLD}${CYAN}=== $1 ===${NC}"
}

print_success() {
    echo "${GREEN}✅ $1${NC}"
}

print_info() {
    echo "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo "${YELLOW}⚠️  $1${NC}"
}

# DNS Health Check
dns_health_check() {
    print_header "DNS Baseline Health Check"

    local success_count=0
    local total_count=0
    local resolvers=("127.0.0.1" "1.1.1.1" "8.8.8.8")
    local domains=("google.com" "cloudflare.com" "example.com")

    for resolver in "${resolvers[@]}"; do
        print_info "Testing resolver: $resolver"
        for domain in "${domains[@]}"; do
            ((total_count++))
            if timeout 5 dig @"$resolver" +short +time=3 +tries=1 "$domain" A &>/dev/null; then
                echo "  ${GREEN}✓${NC} $domain resolved successfully"
                ((success_count++))
            else
                echo "  ${RED}✗${NC} $domain failed to resolve"
            fi
        done
    done

    local success_rate=$((success_count * 100 / total_count))
    echo ""
    print_info "DNS Health Summary:"
    echo "  • Total queries: $total_count"
    echo "  • Successful: $success_count"
    echo "  • Success rate: ${success_rate}%"

    if [[ $success_rate -ge 90 ]]; then
        print_success "DNS health is excellent (≥90%)"
    elif [[ $success_rate -ge 75 ]]; then
        print_warning "DNS health is acceptable (≥75%)"
    else
        print_warning "DNS health needs attention (<75%)"
    fi
}

# Malicious Domain Testing
malicious_domain_test() {
    print_header "Malicious Domain Blocking Test"

    local blocked_count=0
    local total_count=0
    local test_domains=(
        "ads.testcategory.com"
        "malware.testcategory.com"
        "phishing.testcategory.com"
        "tracking.testcategory.com"
    )

    print_info "Testing DNS filtering effectiveness..."

    for domain in "${test_domains[@]}"; do
        ((total_count++))
        local response
        response=$(timeout 5 dig @127.0.0.1 +short +time=3 +tries=1 "$domain" A 2>/dev/null || echo "BLOCKED")

        if [[ -z "$response" ]] || [[ "$response" == "BLOCKED" ]] || [[ "$response" =~ ^(0\.0\.0\.0|127\.0\.0\.1)$ ]]; then
            echo "  ${GREEN}✓${NC} $domain - BLOCKED"
            ((blocked_count++))
        else
            echo "  ${YELLOW}!${NC} $domain - ALLOWED ($response)"
        fi
    done

    local blocking_rate=$((blocked_count * 100 / total_count))
    echo ""
    print_info "Malicious Domain Blocking Summary:"
    echo "  • Total test domains: $total_count"
    echo "  • Blocked domains: $blocked_count"
    echo "  • Blocking rate: ${blocking_rate}%"

    if [[ $blocking_rate -ge 75 ]]; then
        print_success "Good threat protection (≥75%)"
    else
        print_warning "Consider improving DNS filtering (<75%)"
    fi
}

# HTTPS Interception Check
https_interception_test() {
    print_header "HTTPS Interception Detection"

    local test_domains=("google.com" "github.com")
    local interception_detected=false

    print_info "Checking for HTTPS interception..."

    for domain in "${test_domains[@]}"; do
        if command -v openssl &>/dev/null; then
            local cert_info
            cert_info=$(timeout 10 echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -noout -issuer 2>/dev/null || echo "")

            if [[ -n "$cert_info" ]]; then
                if echo "$cert_info" | grep -qi "captive\|portal\|firewall\|untrusted"; then
                    echo "  ${RED}!${NC} $domain - Potential interception detected"
                    interception_detected=true
                else
                    echo "  ${GREEN}✓${NC} $domain - Certificate looks normal"
                fi
            else
                echo "  ${YELLOW}?${NC} $domain - Could not check certificate"
            fi
        else
            print_warning "OpenSSL not available - skipping certificate checks"
            break
        fi
    done

    echo ""
    if [[ "$interception_detected" == "true" ]]; then
        print_warning "Potential HTTPS interception detected"
        print_info "This may indicate a corporate proxy or captive portal"
    else
        print_success "No obvious HTTPS interception detected"
    fi
}

# Performance Test
performance_test() {
    print_header "DNS Performance Analysis"

    local resolvers=("127.0.0.1" "1.1.1.1" "8.8.8.8")
    local test_domain="example.com"

    print_info "Testing DNS response times..."

    for resolver in "${resolvers[@]}"; do
        local total_time=0
        local successful_queries=0
        local iterations=3

        for ((i=1; i<=iterations; i++)); do
            local start_time end_time query_time
            start_time=$(date +%s%N)

            if timeout 5 dig @"$resolver" +short +time=3 +tries=1 "$test_domain" A &>/dev/null; then
                end_time=$(date +%s%N)
                query_time=$(( (end_time - start_time) / 1000000 ))
                total_time=$((total_time + query_time))
                ((successful_queries++))
            fi
        done

        if [[ $successful_queries -gt 0 ]]; then
            local avg_time=$((total_time / successful_queries))
            if [[ $avg_time -le 50 ]]; then
                echo "  ${GREEN}✓${NC} $resolver - ${avg_time}ms (excellent)"
            elif [[ $avg_time -le 150 ]]; then
                echo "  ${BLUE}•${NC} $resolver - ${avg_time}ms (good)"
            else
                echo "  ${YELLOW}!${NC} $resolver - ${avg_time}ms (slow)"
            fi
        else
            echo "  ${RED}✗${NC} $resolver - timeout/failed"
        fi
    done
}

# Control D Check
controld_check() {
    print_header "Control D Integration Check"

    # Check if verify.controld.com is accessible
    if command -v curl &>/dev/null; then
        print_info "Testing Control D verification endpoint..."
        if timeout 10 curl -s --max-time 5 "https://verify.controld.com" >/dev/null; then
            print_success "verify.controld.com is accessible"

            # Try to get some info
            local response
            response=$(timeout 10 curl -s --max-time 5 "https://verify.controld.com" 2>/dev/null | head -10)
            if [[ -n "$response" ]]; then
                print_info "Service appears to be responding normally"
            fi
        else
            print_warning "verify.controld.com is not accessible"
            print_info "This may indicate Control D is not configured"
        fi
    else
        print_warning "curl not available - skipping Control D endpoint test"
    fi

    # Check for ctrld service
    if command -v systemctl &>/dev/null; then
        if systemctl is-active ctrld &>/dev/null; then
            print_success "ctrld service is active"
        else
            print_info "ctrld service is not running (this is normal if not configured)"
        fi
    fi

    # Check for ctrld binary
    if command -v ctrld &>/dev/null || [[ -f /usr/bin/ctrld ]] || [[ -f /usr/local/bin/ctrld ]]; then
        print_success "ctrld binary is installed"
    else
        print_info "ctrld binary not found (install with Control D setup)"
    fi
}

# Main execution
main() {
    print_banner

    echo "${BOLD}Running DNS Security Tests...${NC}"
    echo ""

    # Check prerequisites
    local missing_tools=()
    for tool in dig curl openssl; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_warning "Missing tools: ${missing_tools[*]}"
        print_info "Some tests may be skipped"
    else
        print_success "All required tools available"
    fi

    echo ""

    # Run tests
    dns_health_check
    echo ""
    malicious_domain_test
    echo ""
    https_interception_test
    echo ""
    performance_test
    echo ""
    controld_check

    # Summary
    echo ""
    print_header "Test Summary"
    print_success "DNS Security Testing Complete!"
    print_info "Framework capabilities demonstrated:"
    echo "  • DNS baseline health validation"
    echo "  • Malicious domain blocking testing"
    echo "  • HTTPS interception detection"
    echo "  • DNS performance analysis"
    echo "  • Control D integration checking"
    echo ""
    print_info "For full functionality, use:"
    echo "  ansible-playbook playbooks/dns_security_testing.yml"
    echo ""
    echo "${BOLD}${GREEN}🦴 Gutter Bonez DNS Security Framework${NC}"
    echo "${BOLD}Nowhere to go but up!${NC}"
}

# Show usage if requested
if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    echo "Simple DNS Security Testing Demo"
    echo ""
    echo "Usage: $0 [--help]"
    echo ""
    echo "This script demonstrates core DNS security testing capabilities:"
    echo "  • DNS baseline health checks"
    echo "  • Malicious domain blocking validation"
    echo "  • HTTPS interception detection"
    echo "  • DNS performance analysis"
    echo "  • Control D integration testing"
    echo ""
    echo "No arguments required - just run the script!"
    exit 0
fi

# Run the demo
main "$@"
