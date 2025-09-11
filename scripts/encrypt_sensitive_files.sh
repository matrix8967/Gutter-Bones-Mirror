#!/bin/bash

# Gutter Bonez Sensitive Files Encryption Script
# Encrypts all sensitive files containing network topology, credentials, and infrastructure details
# Author: Azazel (QA & Support Engineer)
# Version: 1.1 - Updated to recommend vault strings approach

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
GUTTER_BONEZ_ROOT="$(dirname "$SCRIPT_DIR")"
VAULT_PASSWORD_FILE="$GUTTER_BONEZ_ROOT/.Vault_Pass.txt"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}========================================${NC}"
    echo ""
}

print_separator() {
    echo ""
    echo -e "${CYAN}----------------------------------------${NC}"
    echo ""
}

# Help function
show_help() {
    cat << EOF
🔐 Gutter Bonez Sensitive Files Encryption Script (Legacy)

⚠️  RECOMMENDATION: Use the new vault_secrets.sh script instead!
    The new script encrypts only secret strings, not entire files,
    making configuration more readable and maintainable.

USAGE:
    $0 [OPTIONS]

NEW APPROACH (RECOMMENDED):
    ./scripts/vault_secrets.sh encrypt-string "mySecret"
    ./scripts/vault_secrets.sh interactive
    ./scripts/vault_secrets.sh find-secrets inventory/Inventory01.ini

OPTIONS:
    -h, --help              Show this help message
    -e, --encrypt           Encrypt sensitive files (default action)
    -d, --decrypt           Decrypt files for editing
    -l, --list              List files that will be encrypted
    -c, --check             Check encryption status of files
    -v, --verify            Verify vault password file exists
    --force                 Force encryption even if files are already encrypted
    --dry-run              Show what would be encrypted without doing it
    --strings              Use vault strings instead of file encryption (NEW!)

DESCRIPTION:
    This script encrypts sensitive files in the Gutter Bonez infrastructure
    automation repository using Ansible Vault.

    ⭐ NEW: Vault strings encrypt only secret values while keeping YAML readable
    📁 OLD: Full file encryption (less maintainable)

FILES ENCRYPTED:
    • inventory/hosts
    • inventory/example_ctrld_deployment.yml
    • group_vars/all.yml
    • group_vars/edgeos.yml
    • group_vars/debian.yml (if contains sensitive data)
    • Any other files with network topology data

VAULT STRINGS VS FULL FILE ENCRYPTION:

  VAULT STRINGS (NEW - RECOMMENDED):
  ✓ Only secrets encrypted, structure visible
  ✓ Easy to diff and review changes
  ✓ Selective encryption of values
  ✓ Better for collaboration

  password: !vault |
            \$ANSIBLE_VAULT;1.1;AES256
            66663...

  FULL FILE ENCRYPTION (OLD):
  ✗ Entire file encrypted, unreadable
  ✗ Hard to review and maintain
  ✗ All or nothing approach

  \$ANSIBLE_VAULT;1.1;AES256
  66663036386439643835653361...

EXAMPLES:
    # NEW APPROACH - Vault strings (recommended)
    ./scripts/vault_secrets.sh encrypt-string "myPassword"
    ./scripts/vault_secrets.sh find-secrets group_vars/all

    # OLD APPROACH - Full file encryption
    $0 --encrypt
    $0 --check
    $0 --decrypt

MIGRATION PATH:
    1. Use vault_secrets.sh to find secrets:
       ./scripts/vault_secrets.sh find-secrets group_vars/all
    2. Replace secrets with vault strings
    3. Test with: ./scripts/vault_secrets.sh validate-file group_vars/all

SECURITY:
    • Uses .Vault_Pass.txt file for encryption password
    • Creates backups before encryption (.pre-vault-backup)
    • Validates file integrity after encryption
    • Prevents accidental double-encryption

EOF
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if ansible-vault is available
    if ! command -v ansible-vault &> /dev/null; then
        log_error "ansible-vault command not found. Please install Ansible."
        exit 1
    fi

    # Check if we're in the right directory
    if [[ ! -f "$GUTTER_BONEZ_ROOT/ansible.cfg" ]]; then
        log_error "Not in the gutter_bonez repository root directory"
        exit 1
    fi

    log_success "Prerequisites check passed"
}

# Verify vault password file
verify_vault_password() {
    log_info "Verifying vault password file..."

    if [[ ! -f "$VAULT_PASSWORD_FILE" ]]; then
        log_error "Vault password file not found: $VAULT_PASSWORD_FILE"
        log_error "Please create the file with your vault password:"
        log_error "  echo 'your_secure_password' > .Vault_Pass.txt"
        log_error "  chmod 600 .Vault_Pass.txt"
        exit 1
    fi

    # Check file permissions
    local perms=$(stat -c %a "$VAULT_PASSWORD_FILE" 2>/dev/null || stat -f %A "$VAULT_PASSWORD_FILE" 2>/dev/null || echo "unknown")
    if [[ "$perms" != "600" ]]; then
        log_warning "Vault password file permissions are not 600, fixing..."
        chmod 600 "$VAULT_PASSWORD_FILE"
    fi

    # Check if file is empty
    if [[ ! -s "$VAULT_PASSWORD_FILE" ]]; then
        log_error "Vault password file is empty"
        exit 1
    fi

    log_success "Vault password file is properly configured"
}

# Define sensitive files to encrypt
get_sensitive_files() {
    local files=(
        "inventory/hosts"
        "inventory/example_ctrld_deployment.yml"
        "inventory/Network.yml"
        "inventory/ctrld.ini"
        "group_vars/all.yml"
        "group_vars/edgeos.yml"
        "group_vars/debian.yml"
        "group_vars/init.yml"
        "group_vars/main.yml"
    )

    # Only return files that exist
    for file in "${files[@]}"; do
        if [[ -f "$GUTTER_BONEZ_ROOT/$file" ]]; then
            echo "$file"
        fi
    done
}

# Check if file is already encrypted
is_encrypted() {
    local file="$1"
    if [[ -f "$file" ]]; then
        head -1 "$file" | grep -q '^\$ANSIBLE_VAULT;'
    else
        return 1
    fi
}

# List files that will be processed
list_files() {
    log_header "📋 Sensitive Files List"

    local files
    mapfile -t files < <(get_sensitive_files)

    log_info "Files that will be encrypted:"
    echo ""

    for file in "${files[@]}"; do
        local full_path="$GUTTER_BONEZ_ROOT/$file"
        local status=""

        if is_encrypted "$full_path"; then
            status="${GREEN}[ENCRYPTED]${NC}"
        elif [[ -f "$full_path" ]]; then
            status="${YELLOW}[PLAINTEXT]${NC}"
        else
            status="${RED}[MISSING]${NC}"
            continue
        fi

        echo -e "  • $file $status"
    done

    echo ""
    log_info "Total files: ${#files[@]}"
}

# Check encryption status
check_status() {
    log_header "🔍 Encryption Status Check"

    local files
    mapfile -t files < <(get_sensitive_files)

    local encrypted=0
    local plaintext=0
    local missing=0

    for file in "${files[@]}"; do
        local full_path="$GUTTER_BONEZ_ROOT/$file"

        if [[ ! -f "$full_path" ]]; then
            echo -e "${RED}✗ MISSING${NC}   - $file"
            ((missing++))
        elif is_encrypted "$full_path"; then
            echo -e "${GREEN}✓ ENCRYPTED${NC} - $file"
            ((encrypted++))
        else
            echo -e "${YELLOW}⚠ PLAINTEXT${NC} - $file"
            ((plaintext++))
        fi
    done

    echo ""
    log_info "Summary:"
    echo "  • Encrypted: $encrypted files"
    echo "  • Plaintext: $plaintext files"
    echo "  • Missing:   $missing files"

    if [[ $plaintext -gt 0 ]]; then
        echo ""
        log_warning "$plaintext files contain sensitive data and should be encrypted"
    fi

    if [[ $encrypted -eq ${#files[@]} && $missing -eq 0 ]]; then
        echo ""
        log_success "All sensitive files are properly encrypted! 🔐"
    fi
}

# Create backup of file before encryption
create_backup() {
    local file="$1"
    local backup_file="${file}.pre-vault-backup"

    if [[ -f "$file" ]] && [[ ! -f "$backup_file" ]]; then
        log_info "Creating backup: $(basename "$backup_file")"
        cp "$file" "$backup_file"
    fi
}

# Encrypt a single file
encrypt_file() {
    local file="$1"
    local force="$2"
    local full_path="$GUTTER_BONEZ_ROOT/$file"

    if [[ ! -f "$full_path" ]]; then
        log_warning "File not found, skipping: $file"
        return 0
    fi

    if is_encrypted "$full_path"; then
        if [[ "$force" != "true" ]]; then
            log_info "Already encrypted, skipping: $file"
            return 0
        else
            log_info "Force mode: re-encrypting: $file"
            # Decrypt first, then re-encrypt
            ansible-vault decrypt --vault-password-file "$VAULT_PASSWORD_FILE" "$full_path"
        fi
    fi

    # Create backup before encryption
    create_backup "$full_path"

    # Encrypt the file
    log_info "Encrypting: $file"
    if ansible-vault encrypt --vault-password-file "$VAULT_PASSWORD_FILE" "$full_path" 2>/dev/null; then
        log_success "Successfully encrypted: $file"

        # Verify encryption
        if is_encrypted "$full_path"; then
            log_success "Encryption verified: $file"
        else
            log_error "Encryption verification failed: $file"
            return 1
        fi
    else
        log_error "Failed to encrypt: $file"
        return 1
    fi
}

# Decrypt files for editing
decrypt_files() {
    log_header "🔓 Decrypting Files for Editing"

    local files
    mapfile -t files < <(get_sensitive_files)

    log_warning "This will decrypt files temporarily for editing"
    log_warning "Remember to re-encrypt before committing!"

    echo ""
    read -p "Continue? (y/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Decryption cancelled"
        return 0
    fi

    local decrypted=0

    for file in "${files[@]}"; do
        local full_path="$GUTTER_BONEZ_ROOT/$file"

        if is_encrypted "$full_path"; then
            log_info "Decrypting: $file"
            if ansible-vault decrypt --vault-password-file "$VAULT_PASSWORD_FILE" "$full_path" 2>/dev/null; then
                log_success "Decrypted: $file"
                ((decrypted++))
            else
                log_error "Failed to decrypt: $file"
            fi
        else
            log_info "Not encrypted, skipping: $file"
        fi
    done

    echo ""
    log_success "Decrypted $decrypted files"
    log_warning "Remember to run '$0 --encrypt' before committing!"
}

# Main encryption function
encrypt_files() {
    local force="$1"
    local dry_run="$2"

    log_header "🔐 Encrypting Sensitive Files"

    local files
    mapfile -t files < <(get_sensitive_files)

    if [[ "$dry_run" == "true" ]]; then
        log_info "DRY RUN MODE - No files will be modified"
        echo ""
    fi

    local encrypted=0
    local skipped=0
    local errors=0

    for file in "${files[@]}"; do
        local full_path="$GUTTER_BONEZ_ROOT/$file"

        if [[ "$dry_run" == "true" ]]; then
            if is_encrypted "$full_path"; then
                echo -e "${GREEN}[DRY RUN]${NC} Would skip (already encrypted): $file"
                ((skipped++))
            elif [[ -f "$full_path" ]]; then
                echo -e "${BLUE}[DRY RUN]${NC} Would encrypt: $file"
                ((encrypted++))
            else
                echo -e "${YELLOW}[DRY RUN]${NC} Would skip (missing): $file"
                ((skipped++))
            fi
        else
            # Only process existing files
            if [[ ! -f "$full_path" ]]; then
                log_info "File not found, skipping: $file"
                ((skipped++))
            elif encrypt_file "$file" "$force"; then
                ((encrypted++))
            else
                log_warning "Failed to encrypt: $file"
                ((errors++))
            fi
        fi
    done

    echo ""
    if [[ "$dry_run" == "true" ]]; then
        log_info "DRY RUN SUMMARY:"
        echo "  • Would encrypt: $encrypted files"
        echo "  • Would skip:    $skipped files"
    else
        log_info "ENCRYPTION SUMMARY:"
        echo "  • Encrypted: $encrypted files"
        echo "  • Skipped:   $skipped files"
        echo "  • Errors:    $errors files"

        if [[ $errors -eq 0 ]]; then
            echo ""
            log_success "All sensitive files encrypted successfully! 🔐"
            log_info "Files are now safe to commit to git"
            echo ""
            log_info "To edit encrypted files use:"
            log_info "  ansible-vault edit <filename>"
            echo ""
            log_info "To decrypt temporarily use:"
            log_info "  $0 --decrypt"
        else
            log_error "Some files failed to encrypt. Please check the errors above."
            exit 1
        fi
    fi
}

# Clean up backup files
cleanup_backups() {
    log_info "Cleaning up backup files..."
    find "$GUTTER_BONEZ_ROOT" -name "*.pre-vault-backup" -delete
    log_success "Backup files cleaned up"
}

# Recommend new vault strings approach
recommend_new_approach() {
    log_header "💡 Recommendation: Use Vault Strings Instead"

    log_info "The new vault_secrets.sh script offers better secret management:"
    echo ""
    echo -e "  ${GREEN}✓${NC} Encrypts only secret values, not entire files"
    echo -e "  ${GREEN}✓${NC} Keeps YAML structure readable and diffable"
    echo -e "  ${GREEN}✓${NC} Easier collaboration and code reviews"
    echo -e "  ${GREEN}✓${NC} Selective encryption of sensitive values"
    echo ""
    log_info "Quick start with vault strings:"
    echo "  ./scripts/vault_secrets.sh encrypt-string 'mySecret'"
    echo "  ./scripts/vault_secrets.sh find-secrets inventory/Inventory01.ini"
    echo "  ./scripts/vault_secrets.sh interactive"
    echo ""
    read -p "Continue with legacy full-file encryption? (y/N): " -n 1 -r
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Consider using the new vault strings approach!"
        exit 0
    fi
}

# Main function
main() {
    local action="encrypt"
    local force=false
    local dry_run=false
    local use_strings=false

    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -e|--encrypt)
                action="encrypt"
                shift
                ;;
            -d|--decrypt)
                action="decrypt"
                shift
                ;;
            -l|--list)
                action="list"
                shift
                ;;
            -c|--check)
                action="check"
                shift
                ;;
            -v|--verify)
                action="verify"
                shift
                ;;
            --force)
                force=true
                shift
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --strings)
                log_info "Vault strings mode - redirecting to vault_secrets.sh"
                exec "$GUTTER_BONEZ_ROOT/scripts/vault_secrets.sh" "$@"
                ;;
            --cleanup-backups)
                action="cleanup"
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo ""
                show_help
                exit 1
                ;;
        esac
    done

    # Change to repository root
    cd "$GUTTER_BONEZ_ROOT"

    # Check prerequisites for most actions
    if [[ "$action" != "help" ]]; then
        check_prerequisites
    fi

    # Recommend new approach for encrypt action
    if [[ "$action" == "encrypt" && "$force" != true ]]; then
        recommend_new_approach
    fi

    # Execute requested action
    case "$action" in
        "encrypt")
            verify_vault_password
            encrypt_files "$force" "$dry_run"
            ;;
        "decrypt")
            verify_vault_password
            decrypt_files
            ;;
        "list")
            list_files
            ;;
        "check")
            check_status
            ;;
        "verify")
            verify_vault_password
            log_success "Vault configuration is valid"
            ;;
        "cleanup")
            cleanup_backups
            ;;
        *)
            log_error "Invalid action: $action"
            exit 1
            ;;
    esac
}

# Handle script interruption
trap 'echo -e "\n${YELLOW}Script interrupted by user${NC}"; exit 130' INT

# Run main function with all arguments
main "$@"
