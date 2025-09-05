#!/bin/bash

# Test script to verify ansible-galaxy requirements installation
# Ensures all collections and roles install without authentication prompts
# Author: Azazel (QA & Support Engineer)

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUTTER_BONEZ_ROOT="$(dirname "$SCRIPT_DIR")"
REQUIREMENTS_FILE="$GUTTER_BONEZ_ROOT/requirements.yml"
TEST_COLLECTIONS_PATH="/tmp/gutter_bonez_test_collections"
TEST_ROLES_PATH="/tmp/gutter_bonez_test_roles"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

print_header() {
    echo "=========================================="
    echo "🧪 Ansible Galaxy Requirements Test"
    echo "=========================================="
    echo ""
}

cleanup_test_directories() {
    log_info "Cleaning up test directories..."
    rm -rf "$TEST_COLLECTIONS_PATH" "$TEST_ROLES_PATH" 2>/dev/null || true
}

setup_test_environment() {
    log_info "Setting up test environment..."

    # Create temporary directories for testing
    mkdir -p "$TEST_COLLECTIONS_PATH"
    mkdir -p "$TEST_ROLES_PATH"

    # Export ansible paths to use temporary directories
    export ANSIBLE_COLLECTIONS_PATH="$TEST_COLLECTIONS_PATH"
    export ANSIBLE_ROLES_PATH="$TEST_ROLES_PATH"

    log_success "Test environment ready"
    log_info "Collections path: $TEST_COLLECTIONS_PATH"
    log_info "Roles path: $TEST_ROLES_PATH"
}

test_requirements_file() {
    log_info "Validating requirements.yml file..."

    if [[ ! -f "$REQUIREMENTS_FILE" ]]; then
        log_error "Requirements file not found: $REQUIREMENTS_FILE"
        return 1
    fi

    log_success "Requirements file exists"

    # Check for Galaxy namespace usage to avoid auth issues
    if grep -q "geerlingguy\." "$REQUIREMENTS_FILE" && ! grep -q "src:.*github" "$REQUIREMENTS_FILE"; then
        log_success "Galaxy namespace format found - no auth prompts expected"
    elif grep -q "https://github.com" "$REQUIREMENTS_FILE"; then
        log_warning "HTTPS GitHub URLs found - may prompt for authentication"
    elif grep -q "git://github.com" "$REQUIREMENTS_FILE"; then
        log_warning "Git protocol found - may not work with ansible-galaxy"
    else
        log_info "Requirements use Galaxy namespace format"
    fi

    # Validate YAML syntax
    if command -v python3 &> /dev/null; then
        if python3 -c "import yaml; yaml.safe_load(open('$REQUIREMENTS_FILE'))" 2>/dev/null; then
            log_success "YAML syntax is valid"
        else
            log_error "YAML syntax is invalid"
            return 1
        fi
    else
        log_warning "Python3 not available - skipping YAML syntax check"
    fi
}

test_collections_installation() {
    log_info "Testing Ansible collections installation..."

    if ! command -v ansible-galaxy &> /dev/null; then
        log_error "ansible-galaxy command not found"
        return 1
    fi

    # Install collections with timeout to prevent hanging on auth prompts
    if timeout 300 ansible-galaxy collection install -r "$REQUIREMENTS_FILE" --collections-path "$TEST_COLLECTIONS_PATH" --force; then
        log_success "Collections installed successfully"

        # List installed collections
        log_info "Installed collections:"
        ansible-galaxy collection list --collections-path "$TEST_COLLECTIONS_PATH" | grep -E "^[a-z]" | while read -r collection; do
            log_success "  ✓ $collection"
        done

    else
        log_error "Collections installation failed or timed out"
        return 1
    fi
}

test_roles_installation() {
    log_info "Testing Ansible roles installation..."

    # Install roles with timeout to prevent hanging on auth prompts
    if timeout 300 ansible-galaxy role install -r "$REQUIREMENTS_FILE" --roles-path "$TEST_ROLES_PATH" --force; then
        log_success "Roles installed successfully"

        # List installed roles
        log_info "Installed roles:"
        if [[ -d "$TEST_ROLES_PATH" ]]; then
            for role_dir in "$TEST_ROLES_PATH"/*; do
                if [[ -d "$role_dir" ]]; then
                    role_name=$(basename "$role_dir")
                    log_success "  ✓ $role_name"
                fi
            done
        fi

    else
        log_error "Roles installation failed or timed out"
        return 1
    fi
}

test_specific_collections() {
    log_info "Testing specific collection functionality..."

    # Test that key collections are available
    local required_collections=(
        "community.general"
        "ansible.posix"
        "community.network"
        "community.routeros"
    )

    for collection in "${required_collections[@]}"; do
        if ansible-galaxy collection list --collections-path "$TEST_COLLECTIONS_PATH" | grep -q "$collection"; then
            log_success "Required collection available: $collection"
        else
            log_error "Required collection missing: $collection"
        fi
    done
}

test_role_structure() {
    log_info "Testing role directory structure..."

    local expected_roles=(
        "geerlingguy.docker"
        "geerlingguy.pip"
    )

    for role in "${expected_roles[@]}"; do
        local role_path="$TEST_ROLES_PATH/$role"
        if [[ -d "$role_path" ]]; then
            log_success "Role directory exists: $role"

            # Check for main task file
            if [[ -f "$role_path/tasks/main.yml" ]]; then
                log_success "  ✓ Tasks file found"
            else
                log_warning "  ⚠ Tasks file missing"
            fi

        else
            log_error "Role directory missing: $role"
        fi
    done
}

generate_test_report() {
    local exit_code=$1

    echo ""
    echo "=========================================="
    echo "📋 TEST REPORT"
    echo "=========================================="
    echo ""
    echo "Requirements file: $REQUIREMENTS_FILE"
    echo "Test collections path: $TEST_COLLECTIONS_PATH"
    echo "Test roles path: $TEST_ROLES_PATH"
    echo ""

    if [[ $exit_code -eq 0 ]]; then
        log_success "✅ All tests passed! Requirements can be installed without issues."
        echo ""
        echo "To install requirements in your environment:"
        echo "  ansible-galaxy install -r requirements.yml"
    else
        log_error "❌ Some tests failed. Check the output above for details."
        echo ""
        echo "Common solutions:"
        echo "  • Use Galaxy namespace format (e.g., geerlingguy.docker)"
        echo "  • Avoid direct GitHub URLs when possible"
        echo "  • Check network connectivity"
        echo "  • Verify ansible-galaxy is installed and updated"
    fi

    echo ""
}

show_help() {
    cat << EOF
Ansible Galaxy Requirements Test Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Enable verbose output
    --keep-temp     Keep temporary test directories after completion

DESCRIPTION:
    This script tests the ansible-galaxy requirements installation
    to ensure all collections and roles can be installed without
    authentication prompts or other issues.

    Tests performed:
    • Requirements file validation
    • Collections installation
    • Roles installation
    • Directory structure verification
    • Galaxy namespace format verification

EXAMPLES:
    # Basic test
    $0

    # Verbose test with detailed output
    $0 --verbose

    # Keep temporary directories for inspection
    $0 --keep-temp

EOF
}

# Main function
main() {
    local keep_temp=false

    print_header

    # Set up trap for cleanup
    if [[ "$keep_temp" == "false" ]]; then
        trap cleanup_test_directories EXIT
    fi

    # Run tests
    setup_test_environment

    local exit_code=0

    test_requirements_file || exit_code=1
    test_collections_installation || exit_code=1
    test_roles_installation || exit_code=1
    test_specific_collections || exit_code=1
    test_role_structure || exit_code=1

    generate_test_report $exit_code

    if [[ "$keep_temp" == "true" ]]; then
        log_info "Keeping temporary directories for inspection"
        log_info "Collections: $TEST_COLLECTIONS_PATH"
        log_info "Roles: $TEST_ROLES_PATH"
    fi

    exit $exit_code
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
        --keep-temp)
            keep_temp=true
            shift
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
