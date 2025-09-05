# 📚 Gutter Bonez Documentation

Welcome to the comprehensive documentation for **Gutter Bonez** - the infrastructure automation toolkit that makes deployment and configuration management across diverse computing environments both reliable and repeatable.

## 🎯 Quick Navigation

| Documentation Section | Description | Target Audience |
|----------------------|-------------|-----------------|
| [🚀 Getting Started](#getting-started) | Installation, setup, first deployment | New users, DevOps |
| [🏗️ System Architecture](#architecture) | Platform support, design patterns | Engineers, Architects |
| [📋 Configuration Guide](#configuration) | Variables, templating, customization | System Administrators |
| [🌐 Network Devices](#network-devices) | Router automation, network testing | Network Engineers |
| [🔐 Security Hardening](#security) | SSH, firewall, compliance baseline | Security Teams |
| [🧪 Testing Strategies](#testing) | QA workflows, chaos engineering | QA Engineers |
| [🔄 CI/CD Integration](#cicd) | GitLab pipelines, automation | DevOps Engineers |
| [🚨 Troubleshooting](#troubleshooting) | Common issues, debugging guide | Support Teams |

## 🚀 Getting Started

### Prerequisites

Before diving into Gutter Bonez, ensure you have:

- **Ansible 2.12+** installed
- **Python 3.8+** for Ansible execution
- **SSH access** to target systems
- **Vault password** for encrypted configurations

```bash
# Quick environment setup
pip3 install ansible>=2.12
ansible-galaxy install -r requirements.yml
echo "your_vault_password" > .Vault_Pass.txt
chmod 600 .Vault_Pass.txt
```

### First Deployment

1. **Inventory Setup**
   ```bash
   cp inventory/hosts.example inventory/hosts
   # Edit inventory/hosts with your systems
   ```

2. **Test Connectivity**
   ```bash
   ansible all -i inventory/hosts -m ping
   ```

3. **Initialize Systems**
   ```bash
   ansible-playbook -i inventory/hosts playbooks/Init.yml
   ```

### Essential Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `ansible-playbook playbooks/site.yml` | Deploy everything | Full infrastructure setup |
| `ansible-playbook playbooks/Init.yml --limit servers` | Initialize specific group | Server setup only |
| `ansible all -m shell -a "uptime"` | Ad-hoc commands | Check system uptime |
| `ansible-vault edit group_vars/ctrld.yml` | Edit secrets | Modify encrypted configs |

## 🏗️ System Architecture

### Platform Support Matrix

| Platform | Support Level | Management Method | Use Cases |
|----------|---------------|-------------------|-----------|
| **Ubuntu/Debian** | 🟢 Full | APT, systemd | Servers, workstations |
| **RHEL/Fedora/CentOS** | 🟢 Full | DNF/YUM, systemd | Enterprise servers |
| **macOS** | 🟡 Good | Homebrew, launchd | Developer workstations |
| **Windows** | 🟡 Good | Chocolatey, services | Enterprise environments |
| **ASUSWRT-Merlin** | 🟢 Full | SSH, nvram | Home/SMB routers |
| **OpenWrt** | 🟢 Full | UCI, procd | Embedded networking |
| **EdgeOS** | 🟢 Full | Configure mode | Enterprise routing |
| **MikroTik** | 🟡 Testing | RouterOS CLI | Network testing |

### Component Architecture

```
gutter_bonez/
├── playbooks/          # Executable automation (what to do)
├── roles/              # Reusable components (how to do it)
├── inventory/          # Target definitions (where to do it)
├── group_vars/         # Configuration data (with what settings)
├── templates/          # Dynamic configuration files
└── docs/              # Documentation and guides
```

### Design Principles

- **Immutable Infrastructure**: Replace, don't modify
- **Idempotent Operations**: Safe to run multiple times
- **Platform Awareness**: Automatic adaptation to target systems
- **Configuration as Code**: Version-controlled infrastructure
- **Security by Default**: Hardened configurations out of the box

## 📋 Configuration Guide

### Variable Hierarchy

Variables are resolved in this order (highest precedence first):

1. **Command line**: `--extra-vars`
2. **Host vars**: `host_vars/hostname.yml`
3. **Group vars**: `group_vars/groupname.yml`
4. **Global vars**: `group_vars/all.yml`
5. **Role defaults**: `roles/rolename/defaults/main.yml`

### Essential Configuration Files

| File | Purpose | Example |
|------|---------|---------|
| `group_vars/all.yml` | Global defaults | SSH ports, security settings |
| `group_vars/ctrld.yml` | DNS service config | Resolver IDs (encrypted) |
| `inventory/hosts` | System definitions | IP addresses, groups |
| `ansible.cfg` | Ansible behavior | Timeouts, connection settings |

### Configuration Examples

**Basic System Setup:**
```yaml
# group_vars/servers.yml
security_config:
  enable_firewall: true
  harden_ssh: true
  fail2ban_enabled: true

ssh_defaults:
  port: 2222
  password_authentication: "no"

package_config:
  upgrade_system: true
  install_dev_tools: false
```

**DNS Service Configuration:**
```yaml
# group_vars/dns_servers.yml
dns_config:
  enable_caching: true
  cache_size: 16384
  metrics_enabled: true
  log_level: "info"

ctrld_upstreams:
  "0":
    name: "Control D - Security"
    type: "doh"
    endpoint: "https://freedns.controld.com/p1"
```

### Templating System

Gutter Bonez uses Jinja2 templating for dynamic configurations:

```jinja2
# SSH configuration template
Port {{ ssh_port | default(22) }}
{% if ansible_system == 'Linux' %}
PermitRootLogin no
{% endif %}
# Platform: {{ ansible_system }}
```

## 🌐 Network Device Management

### Supported Router Platforms

#### ASUSWRT-Merlin
- **Access Method**: SSH with key authentication
- **Config Storage**: `/jffs/` persistent partition
- **Service Management**: Custom init scripts
- **Use Cases**: Home labs, small business

```yaml
# Example ASUSWRT-Merlin configuration
[asuswrt_merlin]
rt-ax88u  ansible_host=192.168.1.1  ansible_user=admin
gt-ax6000 ansible_host=192.168.2.1  ansible_user=admin
```

#### OpenWrt/LEDE
- **Access Method**: SSH, UCI configuration
- **Config Storage**: `/etc/config/` directory
- **Service Management**: procd service manager
- **Use Cases**: Embedded systems, IoT gateways

#### EdgeOS/VyOS
- **Access Method**: SSH, configure mode
- **Config Storage**: `/config/` directory  
- **Service Management**: systemd
- **Use Cases**: Enterprise routing, VPN gateways

### Network Automation Examples

**Router Discovery and Facts:**
```bash
ansible-playbook playbooks/Asus_Merlin.yml --tags discovery
```

**Deploy DNS Service to Routers:**
```bash
ansible-playbook playbooks/install_ctrld.yml --limit routers
```

**Network Testing:**
```bash
ansible routers -m shell -a "ping -c3 8.8.8.8"
ansible routers -m shell -a "nslookup verify.controld.com"
```

## 🔐 Security Hardening

### Security Baseline Features

- **SSH Hardening**: Key-only auth, custom ports, fail2ban
- **Firewall Configuration**: UFW/firewalld with restrictive defaults
- **User Management**: Sudo access, strong passwords disabled
- **System Hardening**: Disable unused services, kernel parameters
- **Audit Logging**: Security event monitoring

### Security Playbook Usage

```bash
# Apply security baseline
ansible-playbook playbooks/Firewall.yml

# Harden SSH across all systems
ansible-playbook playbooks/Init.yml --tags ssh,security

# Check security compliance
ansible all -m shell -a "ufw status"
ansible all -m shell -a "systemctl is-active fail2ban"
```

### Security Configuration

```yaml
# group_vars/all.yml - Security defaults
security_config:
  enable_firewall: true
  harden_ssh: true
  disable_root_login: true
  fail2ban_enabled: true
  password_complexity: true
  audit_logging: true

ssh_defaults:
  port: 2222
  password_authentication: "no"
  max_auth_tries: 3
  client_alive_interval: 300
```

## 🧪 Testing Strategies

### Multi-Environment Testing

Gutter Bonez supports testing across diverse environments:

- **Development**: Rapid iteration, debug logging
- **Staging**: Production-like validation
- **Chaos**: Resilience and failure testing
- **Production**: Verified, monitored deployments

### Testing Commands

```bash
# Development environment with debug
ansible-playbook playbooks/install_ctrld.yml \
  --limit development \
  --extra-vars "ctrld_dev_mode=true"

# Staging validation (dry-run)
ansible-playbook playbooks/site.yml \
  --limit staging \
  --check --diff

# Chaos engineering
ansible-playbook playbooks/install_ctrld.yml \
  --limit chaos_targets \
  --extra-vars "chaos_engineering=true"
```

### QA Validation Workflows

1. **Connectivity Testing**
   ```bash
   ansible all -m ping -i inventory/test.yml
   ```

2. **Service Health Checks**
   ```bash
   ansible all -m systemd -a "name=ctrld" --check
   ```

3. **DNS Resolution Validation**
   ```bash
   ansible dns_servers -m shell -a "dig @127.0.0.1 verify.controld.com +short"
   ```

4. **Network Policy Testing**
   ```bash
   ansible routers -m shell -a "iptables -L -n"
   ```

## 🔄 CI/CD Integration

### GitLab CI/CD Pipeline

The repository includes GitLab CI configuration for:

- **Syntax Validation**: Playbook and template linting
- **Security Scanning**: Ansible-vault and secret detection
- **Integration Testing**: Automated deployment to test environments
- **Submodule Updates**: Automatic `scrolls` dotfiles synchronization

### Pipeline Stages

```yaml
# .gitlab-ci.yml example
stages:
  - validate
  - test
  - deploy
  - verify

validate:
  script:
    - ansible-playbook --syntax-check playbooks/*.yml
    - ansible-lint playbooks/

deploy-staging:
  script:
    - ansible-playbook -i inventory/staging.yml playbooks/site.yml
  environment:
    name: staging
```

### Automation Best Practices

- **Version Control**: All infrastructure changes tracked in Git
- **Environment Promotion**: Staging → Production workflow  
- **Rollback Capability**: Quick recovery from failed deployments
- **Change Documentation**: Commit messages and deployment notes

## 🚨 Troubleshooting

### Common Issues and Solutions

#### SSH Connection Failures
```bash
# Check connectivity
ansible all -m ping -vvv

# Verify SSH configuration
ansible all -m shell -a "sshd -T" --become

# Test manual connection
ssh -vvv -p 2222 user@host
```

#### Service Startup Issues
```bash
# Check service status
ansible all -m systemd -a "name=ctrld"

# View service logs
ansible all -m shell -a "journalctl -u ctrld --no-pager -l"

# Check configuration syntax
ansible all -m shell -a "ctrld run --config /etc/controld/ctrld.toml --test"
```

#### Permission Problems
```bash
# Verify sudo access
ansible all -m shell -a "sudo whoami" --become

# Check file permissions
ansible all -m file -a "path=/etc/controld mode=0755" --become
```

#### Firewall Blocking Access
```bash
# Check UFW status
ansible all -m shell -a "ufw status numbered"

# Add SSH rule
ansible all -m ufw -a "rule=allow port=22 proto=tcp" --become
```

### Debug Mode

Enable verbose Ansible output for troubleshooting:

```bash
# Maximum verbosity
ansible-playbook -vvv playbooks/site.yml

# Enable debug logging in services  
ansible-playbook playbooks/install_ctrld.yml \
  --extra-vars "ctrld_log_level=debug"
```

### Log Analysis

Key log locations by platform:

| Platform | Service | Log Location |
|----------|---------|--------------|
| Linux | ctrld | `journalctl -u ctrld` |
| Linux | SSH | `/var/log/auth.log` |
| Linux | UFW | `/var/log/ufw.log` |
| Router | System | `dmesg`, `/var/log/messages` |
| macOS | ctrld | `/var/log/ctrld.log` |

## 📋 Reference Documentation

### Complete Documentation Index

- **[Installation Guide](installation.md)** - Detailed setup procedures
- **[Platform Support](platforms.md)** - OS-specific configuration
- **[Network Devices](network-devices.md)** - Router and switch management
- **[DNS Services](dns-services.md)** - Control-D and DNS automation
- **[Security Baseline](security.md)** - Hardening procedures
- **[Development Setup](development.md)** - Contributing to the project
- **[API Reference](api-reference.md)** - Variable and template reference
- **[Best Practices](best-practices.md)** - Patterns and conventions
- **[Change Log](CHANGELOG.md)** - Version history and updates

### External Resources

- **[Ansible Documentation](https://docs.ansible.com/)** - Official Ansible docs
- **[Control-D Documentation](https://docs.controld.com/)** - DNS service docs
- **[GitLab CI Documentation](https://docs.gitlab.com/ee/ci/)** - Pipeline reference

### Getting Help

- **[Issues](https://github.com/user/gutter_bonez/issues)** - Bug reports and feature requests
- **[Discussions](https://github.com/user/gutter_bonez/discussions)** - Community Q&A
- **[Contributing](../CONTRIBUTING.md)** - How to contribute to the project

---

## 🏴‍☠️ Philosophy

> *"Always lots left `todo`, but every deployment should be identical, testable, and recoverable."*

**Gutter Bonez** embodies infrastructure as code principles where manual deployment is considered a bug, not a feature. Built for environments where you need to rapidly deploy, test, and validate configurations across diverse computing platforms.

**Remember**: Infrastructure should be code, deployments should be immutable, and chaos should be engineered.

---

*For questions or contributions, see our [contributing guidelines](../CONTRIBUTING.md) or open an [issue](https://github.com/user/gutter_bonez/issues).*