# 🔐 Pre-Commit Security Checklist
**Gutter Bonez Infrastructure Automation Repository**

## 🚨 **CRITICAL - Security Verification Before Commit**

This checklist ensures no sensitive data is accidentally committed to the repository. **ALL items must be verified before pushing to GitLab.**

---

## ✅ **Sensitive Files Encryption Status**

Verify all files containing darkfort network information are encrypted:

```bash
# Quick encryption status check
for file in inventory/hosts inventory/example_ctrld_deployment.yml group_vars/all.yml group_vars/edgeos.yml group_vars/debian.yml group_vars/init.yml group_vars/main.yml; do
  echo -n "$file: "
  head -1 "$file" | grep -q "ANSIBLE_VAULT" && echo "ENCRYPTED ✓" || echo "PLAINTEXT ⚠️"
done
```

**Expected Output:** All files should show `ENCRYPTED ✓`

### **Files That MUST Be Encrypted:**
- [ ] `inventory/hosts` - Contains all darkfort IP addresses and hostnames
- [ ] `inventory/example_ctrld_deployment.yml` - Contains network topology
- [ ] `group_vars/all.yml` - Contains network configuration and IPs
- [ ] `group_vars/edgeos.yml` - Contains EdgeRouter 8 Pro configuration
- [ ] `group_vars/debian.yml` - Contains SSH keys and network references
- [ ] `group_vars/init.yml` - Contains system configuration details
- [ ] `group_vars/main.yml` - Contains duplicate sensitive configuration

---

## 🔍 **Security Scan - No Plaintext Secrets**

Run security scan to ensure no unencrypted sensitive data:

```bash
# Scan for potential secrets in non-encrypted files
grep -r "10\.10\.10\|10\.20\.20\|10\.30\.30\|password\|secret\|token\|key.*=" . \
  --exclude-dir=.git \
  --exclude="*.retry" \
  --exclude="PRE_COMMIT_CHECKLIST.md" \
  --exclude=".Vault_Pass.txt" | \
  grep -v "ANSIBLE_VAULT"
```

**Expected Output:** Should return minimal/no results (only documentation references)

---

## 🛡️ **Vault Password File Protection**

Verify vault password file is properly protected and not committed:

- [ ] `.Vault_Pass.txt` exists and contains your vault password
- [ ] `.Vault_Pass.txt` has permissions `600` (readable only by you)
- [ ] `.Vault_Pass.txt` is listed in `.gitignore`
- [ ] Vault password is secure and documented separately

```bash
# Verify vault file protection
ls -la .Vault_Pass.txt
grep -q "\.Vault_Pass\.txt" .gitignore && echo "✓ In .gitignore" || echo "⚠️ NOT in .gitignore"
```

---

## 📝 **Git Status Check**

Verify what will be committed:

```bash
# Check current git status
git status

# Review staged changes
git diff --cached

# Verify no sensitive files are showing as modified
git status --porcelain | grep -E "(inventory/|group_vars/)" | grep -v "^\?\?"
```

**Requirements:**
- [ ] No unencrypted sensitive files in staging area
- [ ] All encrypted files should show as binary changes
- [ ] `.Vault_Pass.txt` should NOT appear in git status

---

## 🧪 **Functionality Verification**

Test that encrypted files still work with Ansible:

```bash
# Test inventory parsing (should work with encrypted files)
ansible-inventory -i inventory/hosts --list > /dev/null && echo "✓ Inventory parsing works" || echo "⚠️ Inventory parsing failed"

# Test playbook syntax with encrypted files
ansible-playbook --syntax-check -i inventory/hosts playbooks/Init.yml && echo "✓ Playbook syntax OK" || echo "⚠️ Playbook syntax failed"

# Verify vault decryption works
ansible-vault view inventory/hosts | head -5 > /dev/null && echo "✓ Vault decryption works" || echo "⚠️ Vault decryption failed"
```

---

## 🔄 **GitLab CI/CD Compatibility**

Ensure CI/CD pipeline will work with encrypted files:

- [ ] GitLab project has `VAULT_PASSWORD` variable set (masked)
- [ ] `.gitlab-ci.yml` references vault password correctly
- [ ] Test jobs use `--vault-password-file` or `$VAULT_PASSWORD`

```bash
# Check CI configuration mentions vault
grep -q "vault\|VAULT" .gitlab-ci.yml && echo "✓ CI vault config found" || echo "⚠️ No CI vault config"
```

---

## 📚 **Documentation Updates**

Verify documentation reflects encryption:

- [ ] `README.md` mentions encrypted files and vault usage
- [ ] `DARKFORT_QUICKREF.md` has vault commands
- [ ] Any new sensitive files are documented in this checklist

---

## ⚡ **Emergency Procedures**

**If you accidentally commit sensitive data:**

1. **Immediate action:**
   ```bash
   # Remove from staging (if not yet pushed)
   git reset HEAD <sensitive_file>

   # Encrypt the file
   ansible-vault encrypt <sensitive_file>

   # Re-add to staging
   git add <sensitive_file>
   ```

2. **If already pushed:**
   ```bash
   # Contact team immediately
   # Consider repository rotation if highly sensitive
   # Update all credentials referenced in the exposed data
   ```

---

## ✅ **Final Pre-Commit Verification**

Before `git push`, verify:

- [ ] ✅ All sensitive files are encrypted (check above)
- [ ] ✅ No plaintext secrets found in scan
- [ ] ✅ Vault password file is protected and ignored
- [ ] ✅ Git status shows only intended changes
- [ ] ✅ Encrypted files still function with Ansible
- [ ] ✅ CI/CD configuration is compatible
- [ ] ✅ Documentation is updated

---

## 🎯 **Commit Commands**

Once all checks pass:

```bash
# Stage your changes (encrypted files will show as binary)
git add .

# Commit with descriptive message
git commit -m "Full refactor. Minimal testing, maximum vibes. glhf.

- Add comprehensive inventory for darkfort network (encrypted)
- Implement ctrld deployment configurations (encrypted)
- Add testing and chaos engineering frameworks
- Update CI/CD pipeline for encrypted environments
- Enhance security with vault encryption for all sensitive data"

# Push to repository
git push origin main
```

---

## 📞 **Support & Recovery**

**To edit encrypted files:**
```bash
ansible-vault edit inventory/hosts
```

**To temporarily decrypt for troubleshooting:**
```bash
ansible-vault decrypt inventory/hosts --output=-
```

**To check if file is encrypted:**
```bash
head -1 filename | grep -q "ANSIBLE_VAULT" && echo "Encrypted" || echo "Plaintext"
```

---

**Last Updated:** 2024-12-28
**Maintained By:** Azazel (QA & Support Engineer)
**Repository:** Gutter Bonez Infrastructure Automation
**Network:** Darkfort (.darkfort domain)
