#!/bin/bash

# Darkfort Network Configuration Validation Script
# Validates Gutter Bonez configurations for the darkfort network environment
# Author: Azazel (QA & Support Engineer)
# Version: 2.0

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUTTER_BONEZ_ROOT="$(dirname "$SCRIPT_DIR")"
INVENTORY_DIR="$GUTTER_BONEZ_ROOT/inventory"
GROUP_VARS_DIR="$GUTTER_BONEZ_ROOT/group_vars"

# Expected network configuration
EXPECTED_DOMAIN="darkfort"
EXPECTED_PRIMARY_GATEWAY="10.10.10.1"
EXPECTED_PRIMARY_DNS="10.10.10.53"
EXPECTED_SUBNETS=("10.10.10.0/24" "10.20.20.0/24" "10.30.30.0/24")

# Validation results
VALIDATION_ERRORS=0
VALIDATION_WARNINGS=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
    ((VALIDATION_WARNINGS++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((VALIDATION_ERRORS++))
}

print_header() {
    echo "=========================================="
    echo "🏰 Darkfort Network Configuration Validation"
    echo "=========================================="
    echo ""
}

print_separator() {
    echo ""
    echo "----------------------------------------"
    echo ""
}

# Validation functions
validate_directory_structure() {
    log_info "Validating directory structure..."

    local required_dirs=(
        "$INVENTORY_DIR"
        "$GROUP_VARS_DIR"
        "$GUTTER_BONEZ_ROOT/playbooks"
        "$GUTTER_BONEZ_ROOT/roles"
        "$GUTTER_BONEZ_ROOT/roles/ctrld"
        "$GUTTER_BONEZ_ROOT/roles/testing"
        "$GUTTER_BONEZ_ROOT/roles/chaos"
        "$GUTTER_BONEZ_ROOT/roles/network_discovery"
    )

    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            log_success "Directory exists: $(basename "$dir")"
        else
            log_error "Missing directory: $dir"
        fi
    done
}

validate_inventory_files() {
    log_info "Validating inventory files..."

    local required_files=(
        "$INVENTORY_DIR/hosts"
        "$INVENTORY_DIR/example_ctrld_deployment.yml"
    )

    for file in "${required_files[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "Inventory file exists: $(basename "$file")"

            # Check for darkfort domain references
            if grep -q "darkfort" "$file"; then
                log_success "Darkfort domain found in $(basename "$file")"
            else
                log_warning "Darkfort domain not found in $(basename "$file")"
            fi

            # Check for expected IP ranges
            if grep -q "10\.10\.10\." "$file"; then
                log_success "Production subnet (10.10.10.x) found in $(basename "$file")"
            else
                log_warning "Production subnet not found in $(basename "$file")"
            fi

        else
            log_error "Missing inventory file: $file"
        fi
    done
}

validate_group_vars() {
    log_info "Validating group variables..."

    local required_group_vars=(
        "$GROUP_VARS_DIR/all.yml"
        "$GROUP_VARS_DIR/edgeos.yml"
        "$GROUP_VARS_DIR/ctrld.yml"
    )

    for file in "${required_group_vars[@]}"; do
        if [[ -f "$file" ]]; then
            log_success "Group vars file exists: $(basename "$file")"

            # Validate content based on file type
            case "$(basename "$file")" in
                "all.yml")
                    if grep -q "domain_name.*darkfort" "$file"; then
                        log_success "Darkfort domain configured in all.yml"
                    else
                        log_error "Darkfort domain not configured in all.yml"
                    fi

                    if grep -q "primary_gateway.*10\.10\.10\.1" "$file"; then
                        log_success "Primary gateway configured in all.yml"
                    else
                        log_error "Primary gateway not configured in all.yml"
                    fi
                    ;;
                "edgeos.yml")
                    if grep -q "EdgeRouter.*8.*Pro" "$file"; then
                        log_success "EdgeRouter 8 Pro model specified in edgeos.yml"
                    else
                        log_warning "EdgeRouter 8 Pro model not specified in edgeos.yml"
                    fi
                    ;;
            esac
        else
            log_error "Missing group vars file: $file"
        fi
    done
}

validate_ansible_configuration() {
    log_info "Validating Ansible configuration..."

    local ansible_cfg="$GUTTER_BONEZ_ROOT/ansible.cfg"
    if [[ -f "$ansible_cfg" ]]; then
        log_success "Ansible configuration file exists"

        if grep -q "vault_password_file" "$ansible_cfg"; then
            log_success "Vault configuration found in ansible.cfg"
        else
            log_warning "Vault configuration not found in ansible.cfg"
        fi
    else
        log_error "Missing ansible.cfg file"
    fi

    local requirements_yml="$GUTTER_BONEZ_ROOT/requirements.yml"
    if [[ -f "$requirements_yml" ]]; then
        log_success "Requirements file exists"

        # Check for essential collections
        local required_collections=("community.general" "ansible.posix" "community.network")
        for collection in "${required_collections[@]}"; do
            if grep -q "$collection" "$requirements_yml"; then
                log_success "Required collection found: $collection"
            else
                log_warning "Required collection missing: $collection"
            fi
        done

        # Check requirements installation approach
        if grep -q "geerlingguy\." "$requirements_yml" && ! grep -q "src:.*github" "$requirements_yml"; then
            log_success "Using Galaxy namespace format - no authentication issues"
        elif grep -q "https://github.com" "$requirements_yml"; then
            log_warning "HTTPS protocol found for GitHub repositories - may cause auth prompts"
        elif grep -q "git://github.com" "$requirements_yml"; then
            log_warning "Git protocol found - may not work with ansible-galaxy"
        else
            log_info "Requirements use Galaxy namespace format"
        fi
    else
        log_error "Missing requirements.yml file"
    fi
}

validate_playbook_syntax() {
    log_info "Validating playbook syntax..."

    if ! command -v ansible-playbook &> /dev/null; then
        log_warning "Ansible not installed - skipping syntax validation"
        return
    fi

    local playbooks=(
        "$GUTTER_BONEZ_ROOT/playbooks/Init.yml"
        "$GUTTER_BONEZ_ROOT/playbooks/install_ctrld.yml"
        "$GUTTER_BONEZ_ROOT/playbooks/ci_testing.yml"
        "$GUTTER_BONEZ_ROOT/playbooks/EdgeOS.yml"
    )

    for playbook in "${playbooks[@]}"; do
        if [[ -f "$playbook" ]]; then
            # Check if playbook is valid YAML and has basic Ansible structure
            if python3 -c "import yaml; yaml.safe_load(open('$playbook'))" 2>/dev/null; then
                # Basic structure check - look for required keys
                if grep -q "hosts:" "$playbook" && grep -q "tasks:" "$playbook"; then
                    log_success "Playbook structure valid: $(basename "$playbook")"
                else
                    log_warning "Playbook missing required structure: $(basename "$playbook")"
                fi
            else
                log_error "Playbook YAML syntax invalid: $(basename "$playbook")"
            fi
        else
            log_warning "Playbook not found: $(basename "$playbook")"
        fi
    done
}

validate_inventory_syntax() {
    log_info "Validating inventory syntax..."

    if ! command -v ansible-inventory &> /dev/null; then
        log_warning "Ansible not installed - skipping inventory validation"
        return
    fi

    local inventories=(
        "$INVENTORY_DIR/hosts"
        "$INVENTORY_DIR/example_ctrld_deployment.yml"
    )

    for inventory in "${inventories[@]}"; do
        if [[ -f "$inventory" ]]; then
            if ansible-inventory -i "$inventory" --list &> /dev/null; then
                log_success "Inventory syntax valid: $(basename "$inventory")"

                # Check for expected groups
                local expected_groups=("production_servers" "lab_environment" "gateways" "dns_servers")
                for group in "${expected_groups[@]}"; do
                    if ansible-inventory -i "$inventory" --list | grep -q "\"$group\""; then
                        log_success "Expected group found: $group"
                    else
                        log_warning "Expected group missing: $group"
                    fi
                done
            else
                log_error "Inventory syntax invalid: $(basename "$inventory")"
            fi
        fi
    done
}

validate_network_connectivity() {
    log_info "Validating network connectivity (if on darkfort network)..."

    # Check if we're on the darkfort network
    local current_ip
    current_ip=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || echo "unknown")

    if [[ "$current_ip" =~ ^10\.(10|20|30)\.(10|20|30)\. ]]; then
        log_info "Detected darkfort network IP: $current_ip"

        # Test connectivity to key infrastructure
        local key_hosts=(
            "10.10.10.1:EdgeRouter 8 Pro Gateway"
            "10.10.10.53:Primary DNS Server"
        )

        for host_info in "${key_hosts[@]}"; do
            local host="${host_info%%:*}"
            local description="${host_info##*:}"

            if ping -c 1 -W 2 "$host" &> /dev/null; then
                log_success "Connectivity OK: $host ($description)"
            else
                log_warning "Connectivity failed: $host ($description)"
            fi
        done

        # Test DNS resolution
        if dig @10.10.10.53 gateway.darkfort +short +time=3 &> /dev/null; then
            log_success "DNS resolution working: gateway.darkfort"
        else
            log_warning "DNS resolution failed: gateway.darkfort"
        fi

        # Test Control D connectivity
        if dig @10.10.10.53 verify.controld.com +short +time=3 &> /dev/null; then
            log_success "Control D connectivity working"
        else
            log_warning "Control D connectivity failed"
        fi

    else
        log_info "Not on darkfort network (current IP: $current_ip) - skipping connectivity tests"
    fi
}

validate_role_structure() {
    log_info "Validating Ansible role structure..."

    local roles=("ctrld" "testing" "chaos" "network_discovery")

    for role in "${roles[@]}"; do
        local role_path="$GUTTER_BONEZ_ROOT/roles/$role"

        if [[ -d "$role_path" ]]; then
            log_success "Role directory exists: $role"

            # Check for main tasks file
            if [[ -f "$role_path/tasks/main.yml" ]]; then
                log_success "Main tasks file exists for role: $role"
            else
                log_error "Main tasks file missing for role: $role"
            fi

            # Check for templates directory (if applicable)
            case "$role" in
                "testing"|"chaos"|"network_discovery")
                    if [[ -d "$role_path/templates" ]]; then
                        log_success "Templates directory exists for role: $role"
                    else
                        log_warning "Templates directory missing for role: $role"
                    fi
                    ;;
            esac
        else
            log_error "Role directory missing: $role"
        fi
    done
}

validate_ci_configuration() {
    log_info "Validating CI/CD configuration..."

    local gitlab_ci="$GUTTER_BONEZ_ROOT/.gitlab-ci.yml"
    if [[ -f "$gitlab_ci" ]]; then
        log_success "GitLab CI configuration exists"

        # Check for expected stages
        local expected_stages=("validate" "test-smoke" "test-functional" "deploy")
        for stage in "${expected_stages[@]}"; do
            if grep -q "$stage" "$gitlab_ci"; then
                log_success "CI stage found: $stage"
            else
                log_warning "CI stage missing: $stage"
            fi
        done

        # Check for darkfort-specific references
        if grep -q "darkfort\|10\.10\.10" "$gitlab_ci"; then
            log_success "Darkfort network references found in CI config"
        else
            log_warning "No darkfort network references found in CI config"
        fi
    else
        log_error "GitLab CI configuration missing"
    fi
}

print_summary() {
    print_separator
    echo "🏰 DARKFORT VALIDATION SUMMARY"
    echo "=============================="
    echo ""

    if [[ $VALIDATION_ERRORS -eq 0 ]]; then
        log_success "No critical errors found! ✅"
    else
        log_error "Found $VALIDATION_ERRORS critical error(s) ❌"
    fi

    if [[ $VALIDATION_WARNINGS -eq 0 ]]; then
        log_success "No warnings found! ✅"
    else
        log_warning "Found $VALIDATION_WARNINGS warning(s) ⚠️"
    fi

    echo ""
    echo "VALIDATION RESULTS:"
    echo "  Errors:   $VALIDATION_ERRORS"
    echo "  Warnings: $VALIDATION_WARNINGS"
    echo ""

    if [[ $VALIDATION_ERRORS -eq 0 ]]; then
        echo -e "${GREEN}✅ Darkfort configuration is ready for deployment!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Please fix the critical errors before proceeding.${NC}"
        exit 1
    fi
}

# Main execution
main() {
    print_header

    log_info "Starting darkfort network configuration validation..."
    log_info "Gutter Bonez root: $GUTTER_BONEZ_ROOT"
    log_info "Using Galaxy namespace format for requirements to avoid authentication prompts"

    print_separator
    validate_directory_structure

    print_separator
    validate_inventory_files

    print_separator
    validate_group_vars

    print_separator
    validate_ansible_configuration

    print_separator
    validate_playbook_syntax

    print_separator
    validate_inventory_syntax

    print_separator
    validate_role_structure

    print_separator
    validate_ci_configuration

    print_separator
    validate_network_connectivity

    print_separator
    print_summary
}

# Help function
show_help() {
    cat << EOF
Darkfort Network Configuration Validation Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    --dry-run      Show what would be validated without running tests

DESCRIPTION:
    This script validates the Gutter Bonez infrastructure automation
    configuration for the darkfort network environment.

    It checks:
    - Directory structure and file presence
    - Inventory configuration and syntax
    - Group variables and network settings
    - Ansible playbook syntax
    - Role structure completeness
    - CI/CD pipeline configuration
    - Network connectivity (if on darkfort network)

EXAMPLES:
    # Basic validation
    $0

    # Verbose validation
    $0 --verbose

    # Dry run to see what would be checked
    $0 --dry-run

NETWORK ENVIRONMENT:
    Expected Domain: $EXPECTED_DOMAIN
    Primary Gateway: $EXPECTED_PRIMARY_GATEWAY
    Primary DNS: $EXPECTED_PRIMARY_DNS
    Network Subnets: ${EXPECTED_SUBNETS[*]}

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -v|--verbose)
            set -x
            shift
            ;;
        --dry-run)
            log_info "DRY RUN MODE - Showing validation steps without execution"
            echo ""
            echo "Would validate:"
            echo "  • Directory structure"
            echo "  • Inventory files"
            echo "  • Group variables"
            echo "  • Ansible configuration"
            echo "  • Playbook syntax"
            echo "  • Role structure"
            echo "  • CI/CD configuration"
            echo "  • Network connectivity"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Run main function
main "$@"
