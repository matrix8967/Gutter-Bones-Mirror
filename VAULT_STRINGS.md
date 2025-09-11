# 🔐 Gutter Bonez Vault Strings Guide

**Modern secret management with readable configuration files**

---

## 🎯 **Overview**

Vault strings allow you to encrypt **only the secret values** while keeping your YAML/INI files readable and maintainable. This is a major improvement over encrypting entire files.

### **Before vs After**

**❌ OLD: Encrypted entire file (unreadable)**
```yaml
$ANSIBLE_VAULT;1.1;AES256
66663036386439643835653361386437663265336665653539323632353939376439306266373064
3766386661643430623064396537656238376462333234370a343834633234343366623935656366
36613538663431633661653839633639316335343030323731313530383033353162333436383734
3636303162343435370a653538643133303331633234363831653132326531316263316535383436
6236
```

**✅ NEW: Encrypted only secrets (readable structure)**
```yaml
---
# Database Configuration
database_config:
  host: "10.10.10.100"         # ← Readable
  port: 5432                   # ← Readable  
  database: "monitoring"       # ← Readable
  username: !vault |           # ← Only secret encrypted
            $ANSIBLE_VAULT;1.1;AES256
            36383138303339316462383434623938313534303066323037396534326562636534336462663731
  password: !vault |           # ← Only secret encrypted
            $ANSIBLE_VAULT;1.1;AES256
            63616362393933336339633866616436383931643637646266663266613362656666306663643031
```

---

## 🚀 **Quick Start**

### **1. Encrypt a Secret String**
```bash
# Interactive mode (recommended for beginners)
./scripts/vault_secrets.sh interactive

# Direct encryption
./scripts/vault_secrets.sh encrypt-string "mySecretPassword123"
```

### **2. Use in YAML Files**
Copy the output and paste into your config files:
```yaml
admin_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          32626539353664366436393430373237376333666330343265323333336661313333343762383964
          3235666430333231376230653964316461353038336138650a353263353633656130323836336132
```

### **3. Validate Your Configuration**
```bash
# Check if vault strings work
./scripts/vault_secrets.sh validate-file group_vars/all

# Find potential secrets to encrypt
./scripts/vault_secrets.sh find-secrets inventory/Inventory01.ini
```

---

## 🛠️ **Available Commands**

### **String Management**
```bash
# Encrypt a string
./scripts/vault_secrets.sh encrypt-string "secretValue"

# Decrypt a vault string
./scripts/vault_secrets.sh decrypt-string '$ANSIBLE_VAULT;1.1;AES256...'

# Interactive encryption session
./scripts/vault_secrets.sh interactive
```

### **File Operations**
```bash
# Find potential secrets in files
./scripts/vault_secrets.sh find-secrets group_vars/all

# List all vault strings in repository
./scripts/vault_secrets.sh list-vaults

# Validate vault strings in a file
./scripts/vault_secrets.sh validate-file group_vars/all

# Generate secure template
./scripts/vault_secrets.sh generate-template group_vars/all.yml
```

---

## 📋 **Common Use Cases**

### **Network Device Credentials**
```yaml
router_credentials:
  edgerouter:
    username: "Matrix"          # Username not sensitive
    password: !vault |          # Password encrypted
              $ANSIBLE_VAULT;1.1;AES256
              34643864393736633963316239393862356534646466323832383333376434303339346533643737
              
  asuswrt:
    username: "admin"
    password: !vault |
              $ANSIBLE_VAULT;1.1;AES256
              31323761663830666235353562663032653565656566376430343830653736373437336535323331
```

### **API Keys and Tokens**
```yaml
controld_config:
  api_key: !vault |
           $ANSIBLE_VAULT;1.1;AES256
           39343135613266643833373138613664323330646439653763306631626638613432323165323536
           
  device_id: "device_12345"     # Device ID not sensitive
  endpoint: "https://api.controld.com"  # URL not sensitive
```

### **SSH Keys**
```yaml
ssh_config:
  private_key: !vault |
               $ANSIBLE_VAULT;1.1;AES256
               33363535613762663930656566633563646432363236626533666539343330363337356662663264
               
  public_key: "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... user@hostname"  # Public key not sensitive
```

### **Database Connections**
```yaml
databases:
  monitoring:
    host: "10.10.10.100"        # Internal IP not sensitive
    port: 5432                  # Standard port not sensitive
    database: "metrics"         # DB name not sensitive
    username: !vault |          # Username encrypted
              $ANSIBLE_VAULT;1.1;AES256
              36383138303339316462383434623938313534303066323037396534326562636534336462663731
    password: !vault |          # Password encrypted  
              $ANSIBLE_VAULT;1.1;AES256
              63616362393933336339633866616436383931643637646266663266613362656666306663643031
```

---

## 🔍 **Secret Detection Patterns**

The script automatically detects these secret patterns:

- **Passwords**: `password=`, `passwd=`, `pwd=`
- **API Keys**: `api_key=`, `apikey=`, `key=`
- **Tokens**: `token=`, `auth_token=`, `access_token=`
- **SSH Keys**: `-----BEGIN`, `private_key=`
- **Connection strings**: `postgresql://`, `mysql://`
- **URLs with credentials**: `user:pass@host`

### **Run Secret Detection**
```bash
# Check inventory for secrets
./scripts/vault_secrets.sh find-secrets inventory/Inventory01.ini

# Check all group vars
./scripts/vault_secrets.sh find-secrets group_vars/all

# Check with custom pattern
./scripts/vault_secrets.sh find-secrets playbooks/deploy.yml "admin.*password"
```

---

## 🎛️ **Interactive Mode**

For user-friendly secret management:

```bash
./scripts/vault_secrets.sh interactive
```

This will prompt you to:
1. Enter secrets to encrypt
2. Copy/paste the vault strings
3. Continue with more secrets
4. Show usage examples

Perfect for:
- First-time setup
- Adding new secrets
- Learning the workflow

---

## ✅ **Benefits Over Full-File Encryption**

| Feature | Vault Strings ✅ | Full File Encryption ❌ |
|---------|------------------|------------------------|
| **Readability** | Structure visible | Completely encrypted |
| **Diffs** | Clean, meaningful | Unreadable binary changes |
| **Collaboration** | Easy code reviews | Difficult to review |
| **Maintenance** | Edit individual secrets | Decrypt entire file |
| **Selective Security** | Encrypt only what's needed | All-or-nothing |
| **Documentation** | Comments preserved | Comments encrypted |
| **Debugging** | See structure, not secrets | See nothing |

---

## 🔒 **Security Best Practices**

### **What to Encrypt**
✅ **DO encrypt:**
- Passwords and passphrases
- API keys and tokens
- Private SSH keys
- Database credentials
- SSL certificate private keys
- OAuth secrets
- Webhook URLs with tokens

❌ **DON'T encrypt:**
- Hostnames and IP addresses (unless highly sensitive)
- Port numbers
- Public SSH keys
- Database names
- Non-sensitive configuration values
- Documentation and comments

### **Vault Password Management**
```bash
# Secure vault password file
chmod 600 .Vault_Pass.txt

# Never commit vault password
echo ".Vault_Pass.txt" >> .gitignore

# Use different passwords for different environments
# .Vault_Pass_dev.txt, .Vault_Pass_prod.txt
```

---

## 🔄 **Migration from Full-File Encryption**

### **Step 1: Decrypt existing files**
```bash
# Using old script
./scripts/encrypt_sensitive_files.sh --decrypt

# Or directly with ansible-vault
ansible-vault decrypt group_vars/all --vault-password-file .Vault_Pass.txt
```

### **Step 2: Find secrets to encrypt**
```bash
./scripts/vault_secrets.sh find-secrets group_vars/all
```

### **Step 3: Replace with vault strings**
```bash
# Encrypt each secret individually
./scripts/vault_secrets.sh encrypt-string "actualSecretValue"

# Replace in file with vault string format
```

### **Step 4: Validate new format**
```bash
./scripts/vault_secrets.sh validate-file group_vars/all
```

---

## 🧪 **Testing Your Configuration**

### **Validate Vault Strings**
```bash
# Check specific file
./scripts/vault_secrets.sh validate-file group_vars/all

# List all vault strings in repo
./scripts/vault_secrets.sh list-vaults

# Test decryption
ansible all -i inventory/Inventory01.ini -m debug -a "var=vault_variable_name"
```

### **Common Issues**
```bash
# Issue: "Failed to decrypt"
# Solution: Check vault password file
cat .Vault_Pass.txt

# Issue: "Invalid vault format" 
# Solution: Re-encrypt the string
./scripts/vault_secrets.sh encrypt-string "correctSecret"

# Issue: "Variable undefined"
# Solution: Check YAML indentation and format
```

---

## 🔧 **Integration with Playbooks**

### **Using Vault Variables**
Vault strings work exactly like regular variables:

```yaml
# In group_vars/all
database_password: !vault |
                   $ANSIBLE_VAULT;1.1;AES256
                   63616362393933336339633866616436383931643637646266663266613362656666306663643031

# In playbook
- name: Configure database
  template:
    src: database.conf.j2
    dest: /etc/app/database.conf
  vars:
    db_password: "{{ database_password }}"  # ← Automatically decrypted
```

### **Template Usage**
```jinja2
# In template file
[database]
host = {{ db_host }}
port = {{ db_port }}
user = {{ db_username }}
password = {{ db_password }}  # ← Vault string automatically decrypted
```

---

## 📚 **Examples Repository**

Check `examples/vault_strings_example.yml` for comprehensive examples of:
- Basic vault string usage
- Complex data structures
- Multiple environments
- Template integration
- Best practices

---

## 🆘 **Troubleshooting**

### **Common Errors**

**Error: "Failed to encrypt string"**
```bash
# Check vault password file exists and has correct permissions
ls -la .Vault_Pass.txt
chmod 600 .Vault_Pass.txt

# Test vault password
ansible-vault --version
```

**Error: "Invalid vault format"**
```bash
# Re-encrypt the string with proper format
./scripts/vault_secrets.sh encrypt-string "yourSecret"

# Check YAML indentation (use spaces, not tabs)
```

**Error: "Variable undefined"**
```bash
# Verify variable name matches exactly
grep -r "variable_name" group_vars/

# Check YAML syntax
python -c "import yaml; yaml.safe_load(open('group_vars/all'))"
```

### **Debug Mode**
```bash
# Run with verbose output
./scripts/vault_secrets.sh encrypt-string "test" -v

# Check ansible-vault directly
ansible-vault encrypt_string --vault-password-file .Vault_Pass.txt --encrypt-vault-id default "test"
```

---

## 📞 **Getting Help**

```bash
# Script help
./scripts/vault_secrets.sh --help

# Command-specific help
./scripts/vault_secrets.sh encrypt-string --help

# Ansible vault help
ansible-vault encrypt_string --help
```

---

**Happy secure automation! 🔐✨**