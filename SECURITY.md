# 🔐 Security Documentation
**Gutter Bonez Infrastructure Automation Repository**

## 🛡️ Security Overview

This repository contains infrastructure automation for the **darkfort** network environment, including sensitive network topology, device configurations, and deployment credentials. All sensitive data is protected using **Ansible Vault encryption**.

---

## 🔒 Encrypted Assets

### **Critical Files (Ansible Vault Encrypted)**

| File | Content | Security Level |
|------|---------|----------------|
| `inventory/hosts` | Complete darkfort network inventory with IPs, hostnames | 🔴 **CRITICAL** |
| `inventory/example_ctrld_deployment.yml` | ctrld deployment scenarios with network details | 🔴 **CRITICAL** |
| `group_vars/all.yml` | Global network configuration and topology | 🔴 **CRITICAL** |
| `group_vars/edgeos.yml` | EdgeRouter 8 Pro configuration | 🟡 **HIGH** |
| `group_vars/debian.yml` | SSH keys and system configuration | 🟡 **HIGH** |
| `group_vars/init.yml` | System initialization parameters | 🟡 **HIGH** |
| `group_vars/main.yml` | Additional system configuration | 🟡 **HIGH** |

### **Network Information Protected**
- **Production Subnet:** `10.10.10.0/24` (VLAN 10)
- **Lab Subnet:** `10.20.20.0/24` (VLAN 20)
- **DMZ Subnet:** `10.30.30.0/24` (VLAN 30)
- **Device Hostnames:** All `.darkfort` domain systems
- **Service Configurations:** DNS, monitoring, infrastructure services
- **Authentication Details:** SSH keys, service credentials

---

## 🔑 Vault Management

### **Vault Password File**
- **File:** `.Vault_Pass.txt`
- **Permissions:** `600` (owner read/write only)
- **Git Status:** Ignored (listed in `.gitignore`)
- **Storage:** Local only, never committed to repository

### **Encryption Standard**
- **Method:** AES-256 encryption via Ansible Vault
- **Format:** `$ANSIBLE_VAULT;1.1;AES256`
- **Key Derivation:** PBKDF2 with random salt

### **Access Control**
```bash
# View encrypted file
ansible-vault view inventory/hosts

# Edit encrypted file
ansible-vault edit inventory/hosts

# Decrypt to stdout (temporary)
ansible-vault decrypt inventory/hosts --output=-

# Check encryption status
head -1 inventory/hosts | grep -q "ANSIBLE_VAULT"
```

---

## 🚨 Security Policies

### **Commit Requirements**
1. ✅ **All sensitive files MUST be encrypted** before commit
2. ✅ **Vault password file MUST be in `.gitignore`**
3. ✅ **No plaintext network topology** in commits
4. ✅ **Security scan MUST pass** before push
5. ✅ **Encrypted files MUST be functionally tested**

### **Prohibited Data in Plaintext**
- ❌ IP addresses from darkfort networks (`10.x.x.x`)
- ❌ Device hostnames (`.darkfort` domain)
- ❌ SSH keys or certificates
- ❌ Service passwords or tokens
- ❌ Network topology information
- ❌ Infrastructure credentials

### **Allowed Documentation References**
- ✅ Generic network examples (`192.168.1.x`, `example.com`)
- ✅ Public service URLs (`github.com`, `controld.com`)
- ✅ Non-sensitive configuration examples
- ✅ Architecture diagrams without real IPs/hostnames

---

## 🔍 Security Validation

### **Pre-Commit Security Scan**
```bash
# Automated security check
./scripts/encrypt_sensitive_files.sh --check

# Manual plaintext detection
grep -r "10\.10\.10\|10\.20\.20\|10\.30\.30" . \
  --exclude-dir=.git \
  --exclude="SECURITY.md" \
  --exclude=".Vault_Pass.txt" | \
  grep -v "ANSIBLE_VAULT"
```

### **Encryption Verification**
```bash
# Verify all critical files are encrypted
for file in inventory/hosts inventory/example_ctrld_deployment.yml group_vars/all.yml group_vars/edgeos.yml; do
  echo -n "$file: "
  head -1 "$file" | grep -q "ANSIBLE_VAULT" && echo "ENCRYPTED ✓" || echo "PLAINTEXT ❌"
done
```

### **Functional Testing**
```bash
# Ensure encrypted files work with Ansible
ansible-inventory -i inventory/hosts --list > /dev/null
ansible-playbook --syntax-check -i inventory/hosts playbooks/Init.yml
```

---

## 🚨 Incident Response

### **If Sensitive Data is Accidentally Committed**

**Immediate Actions:**
1. 🚨 **STOP** all repository access
2. 📞 **Notify team** immediately
3. 🔄 **Rotate exposed credentials**
4. 📝 **Document the incident**

**Recovery Steps:**
```bash
# If not yet pushed - remove from staging
git reset HEAD <sensitive_file>
ansible-vault encrypt <sensitive_file>
git add <sensitive_file>

# If already pushed - consider repository rotation
# Update all credentials referenced in exposed data
# Review access logs for unauthorized access
```

### **Credential Rotation Checklist**
- [ ] Update vault password
- [ ] Regenerate SSH keys
- [ ] Change router/device passwords
- [ ] Update service credentials
- [ ] Review access logs
- [ ] Update team documentation

---

## 🔄 CI/CD Security Integration

### **GitLab CI/CD Variables**
- `VAULT_PASSWORD` - Masked, protected variable for decryption
- `SSH_PRIVATE_KEY` - Deployment key for infrastructure access
- `CI_PUSH_TOKEN` - Limited scope token for repository updates

### **Pipeline Security**
- Encrypted files are automatically decrypted during CI runs
- Sensitive variables are masked in job logs
- Test environments use isolated networks
- Production deployments require manual approval

### **Security Jobs**
```yaml
security-scan:
  script:
    - grep -r "password\|secret\|key" inventory/ playbooks/ || echo "No obvious secrets found"
    - ./scripts/encrypt_sensitive_files.sh --check
```

---

## 📚 Security Training & Documentation

### **Team Access Requirements**
1. **SSH Key Authentication** - Password authentication disabled
2. **Vault Password Knowledge** - Securely shared via secure channels
3. **Security Training** - Understanding of encryption workflows
4. **Incident Response** - Knowledge of emergency procedures

### **Documentation Security**
- Real network details only in encrypted files
- Public documentation uses example networks
- Architecture diagrams sanitized of real hostnames/IPs
- Security procedures documented but credentials omitted

---

## 🎯 Security Tools & Scripts

### **Encryption Management**
- `scripts/encrypt_sensitive_files.sh` - Automated encryption utility
- `scripts/validate_darkfort_config.sh` - Configuration validation
- `scripts/test_requirements.sh` - Dependency verification
- `PRE_COMMIT_CHECKLIST.md` - Security verification checklist

### **Security Utilities**
```bash
# Encrypt new sensitive file
ansible-vault encrypt <filename>

# Create new encrypted file
ansible-vault create <filename>

# Change vault password
ansible-vault rekey <filename>

# Validate all encrypted files
find . -name "*.yml" -exec grep -l "ANSIBLE_VAULT" {} \;
```

---

## 📞 Security Contacts & Resources

### **Internal Contacts**
- **Primary:** Azazel (QA & Support Engineer)
- **Repository:** `gutter_bonez` infrastructure automation
- **Network:** Darkfort (`.darkfort` domain)

### **External Resources**
- [Ansible Vault Documentation](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [GitLab CI/CD Security Best Practices](https://docs.gitlab.com/ee/ci/security/)
- [Infrastructure Security Guidelines](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#best-practices-for-variables-and-vaults)

---

## 📋 Security Compliance

### **Encryption Standards**
- ✅ **AES-256** encryption for all sensitive data
- ✅ **PBKDF2** key derivation with random salts
- ✅ **Perfect Forward Secrecy** via unique vault passwords
- ✅ **Regular key rotation** on security incidents

### **Access Controls**
- ✅ **Role-based access** to encrypted files
- ✅ **Multi-factor authentication** for GitLab access
- ✅ **SSH key authentication** for infrastructure
- ✅ **Least privilege principle** for service accounts

### **Audit & Monitoring**
- ✅ **Git commit tracking** of all changes
- ✅ **CI/CD pipeline logging** of deployments
- ✅ **Access log monitoring** for infrastructure
- ✅ **Security scan automation** in pipelines

---

**Document Version:** 2.0
**Last Updated:** 2024-12-28
**Security Review:** Required before major releases
**Classification:** Internal Use - Infrastructure Team Only
**Repository:** Gutter Bonez Infrastructure Automation
