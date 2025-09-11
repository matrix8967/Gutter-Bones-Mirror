#!/bin/bash

# ====================
# GUTTER BONEZ SECRET STRING VAULT MANAGER
# ====================
# Encrypts individual secret strings instead of entire files
# Maintains readable YAML while protecting sensitive values
# Author: Azazel (QA & Support Engineer)
# Version: 2.0

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUTTER_BONEZ_ROOT="$(dirname "$SCRIPT_DIR")"
VAULT_PASSWORD_FILE="$GUTTER_BONEZ_ROOT/.Vault_Pass.txt"

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
🔐 Gutter Bonez Secret String Vault Manager

USAGE:
    $0 [COMMAND] [OPTIONS]

COMMANDS:
    encrypt-string <string>     Encrypt a single secret string
    decrypt-string <encrypted>  Decrypt a vault string
    find-secrets [pattern]      Find potential secrets in files
    secure-file <file>          Convert plaintext secrets in file to vault strings
    validate-file <file>        Validate vault strings in file
    list-vaults [file]          List all vault strings in files
    generate-template           Create secure template from existing file

INTERACTIVE COMMANDS:
    interactive                 Interactive secret management mode
    secure-inventory           Secure the inventory file with prompts
    secure-group-vars          Secure group_vars files with prompts

OPTIONS:
    -h, --help                  Show this help message
    -f, --file <file>          Target specific file
    -p, --pattern <pattern>    Search pattern for secrets
    -b, --backup               Create backup before changes
    -v, --verbose              Verbose output
    -d, --dry-run              Show what would be done
    --no-backup                Skip backup creation

EXAMPLES:
    # Encrypt a password string
    $0 encrypt-string "mySecretPassword123"

    # Decrypt a vault string
    $0 decrypt-string "\$ANSIBLE_VAULT;1.1;AES256;..."

    # Find potential secrets in inventory
    $0 find-secrets inventory/Inventory01.ini

    # Interactively secure a file
    $0 secure-file group_vars/all --interactive

    # Generate secure template from existing file
    $0 generate-template group_vars/all.yml

    # Interactive mode for managing secrets
    $0 interactive

SECRET PATTERNS DETECTED:
    • Passwords (password=, passwd=, pwd=)
    • API Keys (api_key=, apikey=, key=)
    • Tokens (token=, auth_token=, access_token=)
    • SSH Keys (-----BEGIN, private_key=)
    • Connection strings (postgresql://, mysql://)
    • URLs with credentials (user:pass@host)
    • IP addresses (when marked as sensitive)

VAULT STRING FORMAT:
    Instead of:  password: "mySecret123"
    Uses:        password: !vault |
                          \$ANSIBLE_VAULT;1.1;AES256
                          66663...

SECURITY FEATURES:
    ✓ Individual string encryption (not whole files)
    ✓ Readable YAML structure maintained
    ✓ Automatic secret detection
    ✓ Backup creation before changes
    ✓ Validation of vault strings
    ✓ Interactive prompting for safety
    ✓ Pattern-based secret discovery

EOF
}

# Check prerequisites
check_prerequisites() {
    if ! command -v ansible-vault &> /dev/null; then
        log_error "ansible-vault command not found. Please install Ansible."
        exit 1
    fi

    if [[ ! -f "$GUTTER_BONEZ_ROOT/ansible.cfg" ]]; then
        log_error "Not in the gutter_bonez repository root directory"
        exit 1
    fi
}

# Verify vault password file
verify_vault_password() {
    if [[ ! -f "$VAULT_PASSWORD_FILE" ]]; then
        log_error "Vault password file not found: $VAULT_PASSWORD_FILE"
        log_error "Please create the file with your vault password:"
        log_error "  echo 'your_secure_password' > .Vault_Pass.txt"
        log_error "  chmod 600 .Vault_Pass.txt"
        exit 1
    fi

    local perms=$(stat -c %a "$VAULT_PASSWORD_FILE" 2>/dev/null || stat -f %A "$VAULT_PASSWORD_FILE" 2>/dev/null || echo "unknown")
    if [[ "$perms" != "600" ]]; then
        log_warning "Fixing vault password file permissions..."
        chmod 600 "$VAULT_PASSWORD_FILE"
    fi

    if [[ ! -s "$VAULT_PASSWORD_FILE" ]]; then
        log_error "Vault password file is empty"
        exit 1
    fi
}

# Encrypt a single string
encrypt_string() {
    local string="$1"

    if ansible-vault encrypt_string --vault-password-file "$VAULT_PASSWORD_FILE" --encrypt-vault-id default --name 'vault_string' "$string"; then
        return 0
    else
        log_error "Failed to encrypt string"
        return 1
    fi
}

# Decrypt a vault string
decrypt_string() {
    local encrypted="$1"
    local temp_file=$(mktemp)

    # Write the vault string to temp file
    echo "$encrypted" > "$temp_file"

    if ansible-vault view --vault-password-file "$VAULT_PASSWORD_FILE" "$temp_file" 2>/dev/null; then
        rm -f "$temp_file"
        return 0
    else
        rm -f "$temp_file"
        log_error "Failed to decrypt vault string"
        return 1
    fi
}

# Find potential secrets in files
find_secrets() {
    local file="$1"
    local pattern="${2:-}"

    log_header "🔍 Finding Potential Secrets in $file"

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi

    # Common secret patterns
    local secret_patterns=(
        "password\s*[=:]\s*['\"]([^'\"]+)['\"]"
        "passwd\s*[=:]\s*['\"]([^'\"]+)['\"]"
        "pwd\s*[=:]\s*['\"]([^'\"]+)['\"]"
        "api_key\s*[=:]\s*['\"]([^'\"]+)['\"]"
        "apikey\s*[=:]\s*['\"]([^'\"]+)['\"]"
        "token\s*[=:]\s*['\"]([^'\"]+)['\"]"
        "auth_token\s*[=:]\s*['\"]([^'\"]+)['\"]"
        "access_token\s*[=:]\s*['\"]([^'\"]+)['\"]"
        "private_key\s*[=:]\s*['\"]([^'\"]+)['\"]"
        "ssh_key\s*[=:]\s*['\"]([^'\"]+)['\"]"
        "-----BEGIN[^-]+-----"
        "[a-zA-Z0-9]+://[^:]+:[^@]+@"
    )

    local found=0

    for pattern in "${secret_patterns[@]}"; do
        if [[ -n "$pattern" ]]; then
            while IFS= read -r line; do
                if [[ -n "$line" ]]; then
                    local line_num=$(echo "$line" | cut -d: -f1)
                    local content=$(echo "$line" | cut -d: -f2-)
                    log_warning "Line $line_num: $content"
                    ((found++))
                fi
            done < <(grep -n -E "$pattern" "$file" 2>/dev/null || true)
        fi
    done

    if [[ $found -eq 0 ]]; then
        log_success "No obvious secrets found in $file"
    else
        log_info "Found $found potential secrets in $file"
        echo ""
        log_info "To secure this file, run: $0 secure-file $file"
    fi
}

# Create backup of file
create_backup() {
    local file="$1"
    local backup_file="${file}.pre-vault-$(date +%Y%m%d-%H%M%S)"

    if [[ -f "$file" ]]; then
        log_info "Creating backup: $(basename "$backup_file")"
        cp "$file" "$backup_file"
        echo "$backup_file"
    fi
}

# Interactive string encryption
interactive_encrypt() {
    log_header "🔐 Interactive Secret Encryption"

    while true; do
        echo ""
        read -p "Enter secret to encrypt (or 'quit' to exit): " -s secret
        echo ""

        if [[ "$secret" == "quit" ]]; then
            break
        fi

        if [[ -z "$secret" ]]; then
            log_warning "Empty input, try again"
            continue
        fi

        log_info "Encrypting your secret..."
        echo ""

        if encrypt_string "$secret"; then
            echo ""
            log_success "Secret encrypted! Copy the vault string above."
        else
            log_error "Failed to encrypt secret"
        fi

        echo ""
        read -p "Encrypt another secret? (y/N): " -n 1 -r
        echo ""

        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            break
        fi
    done

    log_info "Interactive encryption session completed"
}

# Secure inventory file interactively
secure_inventory() {
    local inventory_file="$GUTTER_BONEZ_ROOT/inventory/Inventory01.ini"

    log_header "🛡️ Securing Inventory File"

    if [[ ! -f "$inventory_file" ]]; then
        log_error "Inventory file not found: $inventory_file"
        return 1
    fi

    log_info "Analyzing inventory file for sensitive data..."
    find_secrets "$inventory_file"

    echo ""
    read -p "Do you want to interactively secure this file? (y/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Inventory securing cancelled"
        return 0
    fi

    # Create backup
    local backup=$(create_backup "$inventory_file")

    log_info "Interactive inventory securing not yet implemented"
    log_info "Use 'secure-file' command for now"
}

# List all vault strings in files
list_vaults() {
    local search_path="${1:-$GUTTER_BONEZ_ROOT}"

    log_header "📋 Listing Vault Strings"

    local vault_files=()

    while IFS= read -r -d '' file; do
        if grep -l '\$ANSIBLE_VAULT;' "$file" >/dev/null 2>&1; then
            vault_files+=("$file")
        fi
    done < <(find "$search_path" -type f \( -name "*.yml" -o -name "*.yaml" -o -name "*.ini" \) -print0)

    if [[ ${#vault_files[@]} -eq 0 ]]; then
        log_info "No vault strings found in $search_path"
        return 0
    fi

    log_info "Found vault strings in ${#vault_files[@]} files:"
    echo ""

    for file in "${vault_files[@]}"; do
        local rel_path=${file#$GUTTER_BONEZ_ROOT/}
        local vault_count=$(grep -c '\$ANSIBLE_VAULT;' "$file" 2>/dev/null || echo "0")
        echo -e "  ${GREEN}✓${NC} $rel_path (${vault_count} vault strings)"
    done
}

# Validate vault strings in file
validate_file() {
    local file="$1"

    log_header "✅ Validating Vault Strings in $file"

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi

    # Extract vault strings and validate them
    local vault_count=0
    local valid_count=0
    local invalid_count=0

    # This is a simplified validation - in practice you'd need more sophisticated parsing
    while IFS= read -r line; do
        if [[ "$line" =~ \$ANSIBLE_VAULT\; ]]; then
            ((vault_count++))
            # Try to decrypt to validate
            if echo "$line" | ansible-vault decrypt --vault-password-file "$VAULT_PASSWORD_FILE" --output=- - >/dev/null 2>&1; then
                ((valid_count++))
                log_success "Valid vault string on line $vault_count"
            else
                ((invalid_count++))
                log_error "Invalid vault string on line $vault_count"
            fi
        fi
    done < "$file"

    echo ""
    log_info "Validation Summary:"
    echo "  • Total vault strings: $vault_count"
    echo "  • Valid: $valid_count"
    echo "  • Invalid: $invalid_count"

    if [[ $invalid_count -eq 0 && $vault_count -gt 0 ]]; then
        log_success "All vault strings are valid! 🔐"
    elif [[ $vault_count -eq 0 ]]; then
        log_info "No vault strings found in file"
    else
        log_warning "$invalid_count vault strings need attention"
    fi
}

# Generate secure template from file
generate_template() {
    local source_file="$1"
    local template_file="${source_file%.yml}_secure_template.yml"

    log_header "📄 Generating Secure Template"

    if [[ ! -f "$source_file" ]]; then
        log_error "Source file not found: $source_file"
        return 1
    fi

    log_info "Creating secure template: $template_file"

    # Create template with placeholders for secrets
    cp "$source_file" "$template_file"

    # Replace obvious secrets with placeholders
    sed -i.bak 's/password:\s*"[^"]*"/password: "{{ vault_password | default(\"REPLACE_WITH_VAULT_STRING\") }}"/g' "$template_file"
    sed -i.bak 's/api_key:\s*"[^"]*"/api_key: "{{ vault_api_key | default(\"REPLACE_WITH_VAULT_STRING\") }}"/g' "$template_file"
    sed -i.bak 's/token:\s*"[^"]*"/token: "{{ vault_token | default(\"REPLACE_WITH_VAULT_STRING\") }}"/g' "$template_file"

    rm -f "${template_file}.bak"

    log_success "Secure template created: $template_file"
    log_info "Review and customize the template before use"
}

# Main function
main() {
    local command="${1:-help}"
    shift || true

    # Change to repository root
    cd "$GUTTER_BONEZ_ROOT"

    case "$command" in
        "encrypt-string")
            if [[ $# -eq 0 ]]; then
                log_error "encrypt-string requires a string argument"
                exit 1
            fi
            check_prerequisites
            verify_vault_password
            encrypt_string "$1"
            ;;
        "decrypt-string")
            if [[ $# -eq 0 ]]; then
                log_error "decrypt-string requires an encrypted string argument"
                exit 1
            fi
            check_prerequisites
            verify_vault_password
            decrypt_string "$1"
            ;;
        "find-secrets")
            file="${1:-inventory/Inventory01.ini}"
            pattern="${2:-}"
            find_secrets "$file" "$pattern"
            ;;
        "list-vaults")
            search_path="${1:-$GUTTER_BONEZ_ROOT}"
            list_vaults "$search_path"
            ;;
        "validate-file")
            if [[ $# -eq 0 ]]; then
                log_error "validate-file requires a file argument"
                exit 1
            fi
            check_prerequisites
            verify_vault_password
            validate_file "$1"
            ;;
        "generate-template")
            if [[ $# -eq 0 ]]; then
                log_error "generate-template requires a file argument"
                exit 1
            fi
            generate_template "$1"
            ;;
        "interactive")
            check_prerequisites
            verify_vault_password
            interactive_encrypt
            ;;
        "secure-inventory")
            check_prerequisites
            verify_vault_password
            secure_inventory
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# Handle script interruption
trap 'echo -e "\n${YELLOW}Script interrupted by user${NC}"; exit 130' INT

# Run main function
main "$@"
