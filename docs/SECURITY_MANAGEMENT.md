# 🔐 Security Management Guide

## Overview

This guide provides comprehensive security practices for managing sensitive information in the Gutter Bonez infrastructure automation framework. Proper security management is critical for protecting network credentials, API keys, and infrastructure topology information.

## 🛡️ Security Principles

### Defense in Depth
- **Multiple layers** of security controls
- **Encryption at rest** for all sensitive data
- **Access control** through SSH keys and vault passwords
- **Network isolation** for testing environments
- **Regular rotation** of credentials and keys

### Least Privilege Access
- **Minimal permissions** for each service account
- **Role-based access** to different infrastructure components
- **Time-limited access** tokens where possible
- **Audit trails** for all sensitive operations

## 🔑 Ansible Vault Management

### Vault Password Security

The vault password is the master key for all encrypted data. Protect it carefully:

```bash
# Generate a strong vault password
openssl rand -base64 32 > .vault_password_new

# Test the new password
ansible-vault encrypt test_file.yml --vault-password-file .vault_password_new

# Update .Vault_Pass.txt only after testing
mv .vault_password_new .Vault_Pass.txt
```

**Important**: Never commit `.Vault_Pass.txt` to version control!

### Encrypting Sensitive Files

#### Inventory Files
```bash
# Encrypt inventory containing real network topology
ansible-vault encrypt inventory/hosts --vault-password-file .Vault_Pass.txt

# Edit encrypted inventory
ansible-vault edit inventory/hosts --vault-password-file .Vault_Pass.txt

# View encrypted inventory without modifying
ansible-vault view inventory/hosts --vault-password-file .Vault_Pass.txt
```

#### Variable Files
```bash
# Create and encrypt vault variables
cp group_vars/vault_template.yml group_vars/vault.yml
# Edit with your actual secrets
ansible-vault encrypt group_vars/vault.yml --vault-password-file .Vault_Pass.txt
```

#### Documentation Files
```bash
# Encrypt documentation containing network topology
ansible-vault encrypt DARKFORT_QUICKREF.md --vault-password-file .Vault_Pass.txt
ansible-vault encrypt docs/DARKFORT_NETWORK.md --vault-password-file .Vault_Pass.txt
```

### Using Encrypted Variables

Reference vault variables in your playbooks:

```yaml
# In playbooks/example.yml
- name: Configure service
  template:
    src: config.j2
    dest: /etc/service/config
  vars:
    api_key: "{{ vault_api_key }}"
    database_password: "{{ vault_db_credentials.password }}"
```

Run playbooks with vault:

```bash
# Using vault password file
ansible-playbook playbooks/site.yml --vault-password-file .Vault_Pass.txt

# Using prompt for vault password
ansible-playbook playbooks/site.yml --ask-vault-pass
```

## 🗝️ SSH Key Management

### Key Generation and Rotation

Generate dedicated keys for automation:

```bash
# Generate automation-specific SSH key
ssh-keygen -t ed25519 -f ~/.ssh/gutter_bonez_automation -C "gutter_bonez_automation"

# Generate router-specific SSH key
ssh-keygen -t rsa -b 4096 -f ~/.ssh/router_automation -C "router_automation"
```

### SSH Configuration

Secure SSH configuration in `~/.ssh/config`:

```bash
# Gutter Bonez Infrastructure
Host *.darkfort *.example.local
    User automation
    IdentityFile ~/.ssh/gutter_bonez_automation
    IdentitiesOnly yes
    StrictHostKeyChecking yes
    UserKnownHostsFile ~/.ssh/known_hosts_gutter_bonez

# Routers and network devices
Host router-* gateway-* switch-*
    User admin
    IdentityFile ~/.ssh/router_automation
    IdentitiesOnly yes
    StrictHostKeyChecking yes
    KexAlgorithms +diffie-hellman-group14-sha256
    HostKeyAlgorithms +ssh-rsa
    PubkeyAcceptedKeyTypes +ssh-rsa
```

### Key Distribution

Secure key distribution to infrastructure:

```bash
# Copy key to servers (use initial password, then disable password auth)
ssh-copy-id -i ~/.ssh/gutter_bonez_automation.pub user@server.example.local

# For routers, manually add to authorized_keys through web interface or console
```

## 📡 Network Security

### Network Topology Protection

Sensitive network information to protect:
- **Internal IP addresses** and subnet layouts
- **Device hostnames** and FQDN structures  
- **Network credentials** (router passwords, SNMP communities)
- **Network topology** diagrams and documentation
- **Port configurations** and VLAN assignments

### VLAN Isolation

Implement proper network segmentation:

```yaml
# In inventory - use vault for sensitive networks
production_vlan: "{{ vault_production_vlan_id }}"
lab_vlan: "{{ vault_lab_vlan_id }}"
dmz_vlan: "{{ vault_dmz_vlan_id }}"

# Firewall rules for inter-VLAN blocking
firewall_rules:
  - { from: "{{ vault_lab_subnet }}", to: "{{ vault_production_subnet }}", action: "deny" }
  - { from: "{{ vault_dmz_subnet }}", to: "{{ vault_production_subnet }}", action: "deny" }
```

### DNS Security

Protect DNS infrastructure details:

```yaml
# Use vault for actual DNS server IPs
dns_servers:
  primary: "{{ vault_dns_primary_ip }}"
  secondary: "{{ vault_dns_secondary_ip }}"

# Control D configuration in vault
controld_config: "{{ vault_controld_config }}"
```

## 🔒 Service Credentials Management

### API Keys and Tokens

Store all API credentials in vault:

```yaml
# In group_vars/vault.yml (encrypted)
vault_controld_credentials:
  api_key: "your_actual_controld_api_key"
  device_id: "your_actual_device_id"

vault_monitoring_credentials:
  grafana_api_key: "your_actual_grafana_key"
  prometheus_token: "your_actual_prometheus_token"

vault_cloud_credentials:
  aws_access_key: "your_actual_aws_key"
  aws_secret_key: "your_actual_aws_secret"
```

### Database Credentials

Secure database connection information:

```yaml
# Database credentials in vault
vault_database_credentials:
  host: "{{ vault_db_host }}"
  username: "{{ vault_db_user }}"
  password: "{{ vault_db_password }}"
  ssl_cert: "{{ vault_db_ssl_cert }}"
```

## 🛡️ GitLab CI/CD Security

### Secure CI Variables

Configure sensitive CI/CD variables in GitLab:

```yaml
# In .gitlab-ci.yml - reference protected variables
variables:
  VAULT_PASS: "${VAULT_PASSWORD}"  # Protected variable in GitLab
  SSH_PRIVATE_KEY: "${AUTOMATION_SSH_KEY}"  # Protected variable

script:
  - echo "$SSH_PRIVATE_KEY" | tr -d '\r' > ~/.ssh/id_rsa
  - chmod 600 ~/.ssh/id_rsa
  - ansible-playbook playbooks/deploy.yml --vault-password-file <(echo "$VAULT_PASS")
```

### Pipeline Security

Secure pipeline practices:

- **Protected branches**: Only allow deployment from main/master
- **Protected variables**: Mark sensitive variables as protected
- **Masked variables**: Prevent variables from appearing in job logs
- **Limited runners**: Use specific runners for sensitive operations

## 📋 Security Checklist

### Before Committing Code

- [ ] All sensitive files encrypted with ansible-vault
- [ ] No real IP addresses in example files
- [ ] No passwords or API keys in plain text
- [ ] SSH keys not committed to repository
- [ ] .gitignore updated with security patterns
- [ ] Vault password file in .gitignore
- [ ] Documentation sanitized of sensitive information

### Regular Security Maintenance

- [ ] Rotate vault passwords quarterly
- [ ] Rotate SSH keys annually
- [ ] Update API keys when expired
- [ ] Review vault access permissions
- [ ] Audit encrypted file contents
- [ ] Update security documentation
- [ ] Review GitLab CI/CD variables

### Infrastructure Security

- [ ] SSH password authentication disabled
- [ ] SSH key-only authentication enabled
- [ ] Firewall rules properly configured
- [ ] Network segmentation implemented
- [ ] Monitoring and alerting configured
- [ ] Backup encryption enabled
- [ ] Log retention policies in place

## 🚨 Security Incident Response

### Compromised Credentials

If credentials are compromised:

1. **Immediate Actions**:
   ```bash
   # Revoke compromised SSH keys
   ssh user@affected-server "sed -i '/compromised-key/d' ~/.ssh/authorized_keys"
   
   # Change compromised passwords immediately
   ansible-vault edit group_vars/vault.yml
   
   # Rotate API keys
   # Update keys in vault and redeploy affected services
   ```

2. **Investigation**:
   - Review access logs for unauthorized activity
   - Check for unauthorized configuration changes
   - Verify integrity of encrypted files

3. **Recovery**:
   - Deploy new credentials across infrastructure
   - Verify all services are functioning with new credentials
   - Update documentation with incident details

### Vault Password Compromise

If vault password is compromised:

```bash
# Generate new vault password
openssl rand -base64 32 > .vault_password_new

# Re-encrypt all vault files with new password
ansible-vault rekey group_vars/vault.yml --vault-password-file .Vault_Pass.txt --new-vault-password-file .vault_password_new
ansible-vault rekey inventory/hosts --vault-password-file .Vault_Pass.txt --new-vault-password-file .vault_password_new

# Update vault password file
mv .vault_password_new .Vault_Pass.txt

# Update GitLab CI/CD variables
# Update all team members with new vault password
```

## 📚 Security Resources

### Documentation References

- [Ansible Vault Best Practices](https://docs.ansible.com/ansible/latest/user_guide/vault.html)
- [SSH Security Hardening](https://wiki.mozilla.org/Security/Guidelines/OpenSSH)
- [Network Security Fundamentals](https://docs.ansible.com/ansible/latest/network/getting_started/basic_concepts.html)

### Tools and Utilities

- **ansible-vault**: Encryption/decryption tool
- **ssh-audit**: SSH configuration security scanner
- **lynis**: System security auditing tool
- **nmap**: Network discovery and security auditing

### Monitoring and Alerting

- **fail2ban**: Intrusion prevention system
- **logwatch**: Log monitoring and reporting
- **OSSEC**: Host-based intrusion detection
- **Prometheus/Grafana**: Infrastructure monitoring

## 🎯 Security Training

### Team Education

Ensure all team members understand:

- **Vault management** procedures and best practices
- **SSH key lifecycle** management
- **Network security** principles and VLAN isolation
- **Incident response** procedures
- **GitLab CI/CD** security features

### Regular Security Reviews

- **Monthly**: Review and rotate temporary credentials
- **Quarterly**: Full security audit and credential rotation
- **Annually**: Comprehensive security assessment
- **As needed**: Incident-driven security updates

---

**🦴 Gutter Bonez Security Management**  
*Security is not a destination, it's a journey. Nowhere to go but up.*

> **Remember**: Security is everyone's responsibility. When in doubt, encrypt it, rotate it, and document it.