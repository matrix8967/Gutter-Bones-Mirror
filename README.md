# 🦴 Gutter Bonez: Infrastructure Automation Toolkit

**Skeleton Scripts. Nowhere to go but up.**

A comprehensive Ansible-based automation framework for infrastructure deployment, configuration management, and chaos engineering across diverse computing environments. Built for QA engineers, DevOps practitioners, and anyone who needs to rapidly deploy and test configurations across everything from enterprise Windows environments to embedded router systems.

## 🏰 Darkfort Network Environment

This toolkit is optimized for the **darkfort** network infrastructure:
- **Domain:** `.darkfort`
- **Primary Gateway:** EdgeRouter 8 Pro (10.10.10.1)
- **Network Topology:** Segmented VLAN architecture
  - Production: `10.10.10.0/24` (VLAN 10)
  - Lab/Testing: `10.20.20.0/24` (VLAN 20) - Isolated
  - DMZ/Guest: `10.30.30.0/24` (VLAN 30) - Isolated

## 🎯 What This Does

**Gutter Bonez** provides **immutable, idempotent automation** for:

### 🖥️ **System Administration**
- **Multi-platform system initialization** (Linux, Windows, macOS)
- **User account management** with SSH key deployment
- **Package management** and system hardening
- **Dotfiles and configuration synchronization**
- **Security baseline implementation**

### 🌐 **Network Infrastructure** 
- **Router and firewall management** (ASUSWRT-Merlin, OpenWrt, EdgeOS, MikroTik)
- **DNS service deployment** (Control-D ctrld, Pi-hole, Unbound)
- **Network device discovery and configuration**
- **VLAN and network segmentation testing**

### 🔧 **Development Environment Setup**
- **Containerized development stacks** (Docker, Podman)
- **Language runtime management** (Python, Node.js, Go)
- **IDE and toolchain configuration**
- **Git workflow and hooks setup**

### 🧪 **Testing & QA Automation**
- **Chaos engineering scenarios** for network resilience testing
- **Multi-environment validation** (dev, staging, production)
- **DNS security testing framework** with threat detection and HTTPS interception analysis
- **DNS resolution testing and validation** across multiple resolvers
- **Performance benchmarking automation** with latency profiling

### ☁️ **Cloud & Virtualization**
- **KVM/QEMU virtual machine provisioning**
- **Container orchestration** (Docker Swarm, basic Kubernetes)
- **Cloud provider integration** preparation
- **Infrastructure as Code** patterns

## 🏗️ Architecture & Design Philosophy

### **Immutable Infrastructure Principles**
- ✅ **Idempotent operations** - Safe to run multiple times
- ✅ **Configuration validation** - Syntax and logic checking
- ✅ **Atomic deployments** - All-or-nothing updates
- ✅ **Rollback capabilities** - Quick recovery from failures
- ✅ **Platform awareness** - Automatic adaptation to target systems
- ✅ **Secret management** - Encrypted credentials and tokens

### **Platform Support Matrix**

| Platform | Support Level | Primary Use Cases | Darkfort Usage |
|----------|---------------|-------------------|----------------|
| **Pop!_OS/Ubuntu** | 🟢 Full | Desktop workstations, development | QA workstation, DNS servers |
| **Fedora/RHEL** | 🟢 Full | Servers, enterprise environments | Development workstation |
| **Debian** | 🟢 Full | Servers, embedded systems | Production servers, DMZ |
| **Windows 10/11** | 🟡 Good | Desktop testing, enterprise | Lab testing environment |
| **Windows Server** | 🟡 Good | Active Directory, enterprise services | Lab domain controller |
| **macOS** | 🟡 Good | Developer workstations | Not currently deployed |
| **EdgeOS** | 🟢 Full | Enterprise routing, network labs | **Primary Gateway (EdgeRouter 8 Pro)** |
| **ASUSWRT-Merlin** | 🟢 Full | Router automation, network testing | Lab router testing (GT-AX6000) |
| **FreshTomato** | 🟢 Full | Embedded networking, custom firmware | Lab router testing (R7000) |
| **MikroTik RouterOS** | 🟡 Good | Network testing, WISP deployments | Future lab expansion |

## 🚀 Quick Start

### **Prerequisites**

```bash
# Install Ansible and dependencies
pip3 install ansible

# Install requirements (uses Galaxy namespace format to avoid auth prompts)
ansible-galaxy install -r requirements.yml

# Test requirements installation
./scripts/test_requirements.sh

# Set up vault password for encrypted secrets
echo "your_vault_password" > .Vault_Pass.txt
chmod 600 .Vault_Pass.txt

# Verify connectivity to target hosts
ansible all -i inventory/hosts -m ping
```

### **Common Operations**

#### **Initialize New System in Darkfort Network**
```bash
# Initialize a new server in production subnet
ansible-playbook -i inventory/hosts playbooks/Init.yml \
  --limit production_servers \
  --ask-become-pass

# Initialize lab testing environment
ansible-playbook -i inventory/hosts playbooks/Init.yml \
  --limit lab_environment \
  --ask-become-pass
```

#### **Deploy Control D Infrastructure**
```bash
# Deploy primary DNS resolver
ansible-playbook -i inventory/example_ctrld_deployment.yml \
  playbooks/install_ctrld.yml \
  --limit dns_primary_servers

# Deploy to EdgeRouter 8 Pro gateway
ansible-playbook -i inventory/example_ctrld_deployment.yml \
  playbooks/install_ctrld.yml \
  --limit gateway_routers

# Full darkfort network deployment
ansible-playbook -i inventory/example_ctrld_deployment.yml \
  playbooks/install_ctrld.yml \
  --limit production_deployment
```

#### **Configure Development Environment**
```bash
# Validate darkfort configuration
./scripts/validate_darkfort_config.sh

# Configure development environment
ansible-playbook -i inventory/hosts playbooks/Dots.yml \
  --limit workstations \
  --extra-vars "setup_dev_tools=true"
```

#### **Network Discovery and Testing**
```bash
# Discover darkfort network topology
ansible-playbook -i inventory/hosts -m include_role -a name=network_discovery \
  --limit production_servers

# Test router configurations in lab environment
ansible-playbook -i inventory/example_ctrld_deployment.yml \
  playbooks/install_ctrld.yml \
  --limit router_testing

# EdgeRouter 8 Pro configuration
ansible-playbook -i inventory/hosts playbooks/EdgeOS.yml \
  --limit gateways
```

#### **DNS Security Testing & Validation**
```bash
# Comprehensive DNS security testing framework
ansible-playbook -i inventory/example_dns_security.yml \
  playbooks/dns_security_testing.yml

# Test specific security categories
ansible-playbook -i inventory/hosts playbooks/dns_security_testing.yml \
  --extra-vars "dns_security_tests=['baseline','malicious_blocking','https_interception']"

# Control D integration testing
ansible-playbook -i inventory/hosts playbooks/dns_security_testing.yml \
  --extra-vars "dns_controld_integration=true test_environment=production"

# Interactive DNS security demo
./scripts/demo_dns_security.sh

# DNS security testing in CI/CD pipeline
ansible-playbook -i inventory/hosts playbooks/site.yml \
  --extra-vars "dns_security_testing=true"
```

#### **Testing and Quality Assurance**
```bash
# Run comprehensive CI testing pipeline
ansible-playbook -i inventory/hosts playbooks/ci_testing.yml \
  --limit testing_machines \
  --tags smoke,functional

# Chaos engineering (lab environment only)
ansible-playbook -i inventory/hosts playbooks/ci_testing.yml \
  --limit chaos_testing_targets \
  --tags chaos

# System updates and maintenance
ansible-playbook -i inventory/hosts playbooks/Upgrade.yml \
  --limit "lab_environment:dmz_environment"
```

## 📁 Repository Structure

```
gutter_bonez/
├── 📂 playbooks/           # Executable automation scripts
│   ├── 🖥️  Init.yml                    # System initialization
│   ├── 🖥️  Debian.yml                  # Debian-specific setup  
│   ├── 🖥️  RHEL.yml                    # Red Hat family setup
│   ├── 🖥️  Darwin.yml                  # macOS configuration
│   ├── 🖥️  Windows.yml                 # Windows system setup
│   ├── 🌐 Asus_Merlin.yml              # ASUSWRT-Merlin router config
│   ├── 🌐 EdgeOS.yml                   # EdgeOS/VyOS networking
│   ├── 🌐 MikroTik.yml                 # MikroTik RouterOS management
│   ├── 🔧 install_ctrld.yml            # Control-D DNS deployment
│   ├── 🔧 install_ctrld_custom_config.yml # Advanced DNS configuration
│   ├── 🎨 Dots.yml                     # Dotfiles synchronization
│   ├── 🔒 Firewall.yml                 # Security hardening
│   ├── 📦 RPMs.yml                     # Package management
│   └── ⬆️  Upgrade.yml                  # System updates
├── 📂 roles/               # Reusable automation components
│   ├── 🎯 common/                      # Shared configurations
│   ├── 🐧 debian/                      # Debian-specific tasks
│   ├── 🎩 rhel/                        # RHEL-family tasks  
│   ├── 🔧 init/                        # System initialization
│   ├── 🌐 ctrld/                       # DNS service management
│   └── 📜 scrolls/                     # Dotfiles & configs (submodule)
├── 📂 inventory/           # Infrastructure definitions
│   ├── 🏠 hosts                        # Basic host inventory
│   ├── 🌐 Network.yml                  # Network devices (encrypted)
│   ├── 💻 ctrld.ini                    # DNS-specific inventory
│   └── 📋 example_ctrld_deployment.yml # Comprehensive example
├── 📂 group_vars/          # Configuration variables
│   ├── 🔐 ctrld.yml                    # DNS service config (encrypted)
│   └── 📄 [various].yml               # Platform-specific variables
└── 📄 ansible.cfg          # Ansible behavior configuration
```

## 🎛️ Core Components

### **System Initialization (`Init.yml`)**
Comprehensive system setup including:
- User account creation with SSH key deployment
- Package installation and system updates  
- Security hardening (UFW firewall, SSH configuration)
- Hostname and network configuration
- MOTD and system branding

### **Platform-Specific Setup**
- **`Debian.yml`** - APT package management, systemd services
- **`RHEL.yml`** - DNF/YUM packages, SELinux configuration  
- **`Darwin.yml`** - Homebrew packages, launchd services
- **`Windows.yml`** - Chocolatey packages, Windows services

### **Network Infrastructure**
- **`Asus_Merlin.yml`** - ASUSWRT-Merlin router configuration
- **`EdgeOS.yml`** - Ubiquiti EdgeRouter management
- **`MikroTik.yml`** - RouterOS configuration and monitoring
- **DNS Services** - Control-D ctrld deployment with platform awareness

### **Configuration Management** 
- **`Dots.yml`** - Dotfiles synchronization from `scrolls` submodule
- **`Firewall.yml`** - UFW, iptables, and Windows Firewall rules
- **Shared configs** via Git submodule for consistency

## 🔧 Configuration Examples

### **Basic Host Inventory**
```yaml
# inventory/hosts
[workstations]
pop-os-desktop ansible_host=192.168.1.100 ansible_user=azazel
fedora-laptop  ansible_host=192.168.1.101 ansible_user=azazel  

[servers]  
ubuntu-server  ansible_host=192.168.1.102 ansible_user=azazel
debian-docker  ansible_host=192.168.1.103 ansible_user=docker

[routers]
rt-ax88u      ansible_host=192.168.1.1   ansible_user=admin
edgerouter    ansible_host=192.168.1.1   ansible_user=ubnt
```

### **DNS Service Configuration**
```yaml
# group_vars/ctrld.yml (encrypted with ansible-vault)
ctrld_listeners:
  "0":
    ip: "127.0.0.1"
    port: 53
    policy_name: "Main Policy"
    rules:
      - "*.local": ["upstream.local"]
      - "verify.controld.com": ["upstream.0"]

ctrld_upstreams:
  "0": 
    name: "Control D - Security"
    type: "doh"
    endpoint: "https://freedns.controld.com/p1"
    bootstrap_ip: "76.76.2.11"
```

### **Development Environment Variables**
```yaml
# group_vars/workstations.yml
dev_packages:
  - git
  - zsh
  - tmux
  - neovim
  - docker.io
  - nodejs
  - python3-pip

dotfiles_repo: "https://gitlab.com/matrix8967/scrolls.git"
setup_dev_tools: true
configure_shell: true
```

## 🌐 Network Device Automation

### **Router Support Matrix**

| Router/Firmware | Management Method | Config Persistence | Status |
|-----------------|-------------------|-------------------|---------|
| **ASUSWRT-Merlin** | SSH + nvram commands | `/jffs/` partition | ✅ Production Ready |
| **OpenWrt/LEDE** | SSH + UCI commands | `/etc/config/` | ✅ Production Ready |  
| **EdgeOS/VyOS** | SSH + configure commands | `/config/` | ✅ Production Ready |
| **MikroTik RouterOS** | SSH + RouterOS commands | System storage | 🟡 Testing |
| **FreshTomato** | SSH + nvram commands | `/jffs/` partition | 🟡 Testing |

### **Router Deployment Example**
```bash
# Deploy to all ASUSWRT-Merlin routers
ansible-playbook -i inventory/Network.yml \
  playbooks/Asus_Merlin.yml \
  --limit asuswrt_merlin \
  --extra-vars "collect_system_info=true"

# Configure EdgeRouter with custom settings
ansible-playbook -i inventory/Network.yml \
  playbooks/EdgeOS.yml \
  --limit edgerouters \
  --extra-vars "configure_vlans=true vlan_config=production"
```

## 🧪 Testing & Quality Assurance

### **Multi-Environment Testing**
```bash
# Development environment validation
ansible-playbook playbooks/install_ctrld.yml \
  --limit development \
  --extra-vars "ctrld_dev_mode=true"

# Production readiness check  
ansible-playbook playbooks/install_ctrld.yml \
  --limit staging \
  --check --diff
```

### **Chaos Engineering**
```bash
# Network resilience testing
ansible-playbook playbooks/install_ctrld.yml \
  --limit chaos_targets \
  --extra-vars "chaos_engineering=true"

# DNS failover validation
ansible all -i inventory/chaos.yml -m shell \
  -a "dig @127.0.0.1 verify.controld.com +timeout=2"
```

### **Performance Benchmarking**
```bash  
# DNS resolution performance testing
ansible routers -i inventory/Network.yml -m shell \
  -a "time nslookup google.com 127.0.0.1"

# System resource monitoring during load
ansible servers -m shell \
  -a "top -bn1 | head -20"
```

## 🔐 Security & Secrets Management

### **Ansible Vault Integration**
```bash
# Edit encrypted configurations
ansible-vault edit group_vars/ctrld.yml
ansible-vault edit inventory/Network.yml

# View encrypted content
ansible-vault view group_vars/ctrld.yml

# Run playbook with vault password
ansible-playbook --ask-vault-pass playbooks/install_ctrld.yml
```

### **SSH Key Management** 
```bash
# Deploy SSH keys to new systems
ansible-playbook playbooks/Init.yml \
  --extra-vars "copy_pub_key='$(cat ~/.ssh/id_rsa.pub)'"

# Rotate SSH keys across infrastructure
ansible all -m authorized_key \
  -a "user=azazel key='{{ lookup('file', '~/.ssh/new_key.pub') }}'"
```

## 📊 Monitoring & Observability

### **Health Checks**
```bash
# Verify DNS service health across infrastructure
ansible all -m shell -a "systemctl is-active ctrld"

# Check system resources  
ansible all -m setup -a "filter=ansible_meminfo_mb"

# Network connectivity validation
ansible routers -m shell -a "ping -c3 8.8.8.8"
```

### **Log Aggregation**
```bash
# Collect service logs from multiple hosts
ansible servers -m shell \
  -a "journalctl -u ctrld --since '1 hour ago' --no-pager"

# System error detection
ansible all -m shell \
  -a "grep -i error /var/log/syslog | tail -10"
```

## 🔄 Continuous Integration & Deployment

### **GitLab CI/CD Integration**
The repository includes GitLab CI configuration for:
- Automatic submodule updates (`scrolls` dotfiles)
- Syntax validation of playbooks and templates
- Integration testing in isolated environments
- Automated deployment to staging infrastructure

### **Pre-commit Hooks**
```bash
# Install pre-commit hooks for quality assurance
pip install pre-commit
pre-commit install

# Manual validation
ansible-playbook --syntax-check playbooks/*.yml
ansible-lint playbooks/*.yml
```

## 🚨 Troubleshooting

### **Common Issues & Solutions**

**SSH Connection Failures:**
```bash  
# Test connectivity
ansible all -m ping -vvv

# Check SSH configuration
ansible all -m shell -a "ssh -o ConnectTimeout=5 user@host echo test"
```

**Permission Issues:**
```bash
# Verify sudo access
ansible all -m shell -a "sudo whoami" --become

# Check file permissions  
ansible all -m file -a "path=/etc/ctrld mode=0755" --become
```

**Service Startup Failures:**
```bash
# Check service status
ansible all -m systemd -a "name=ctrld state=started" --become

# View service logs
ansible all -m shell -a "journalctl -u ctrld --no-pager -l"
```

### **Debug Mode**
```bash
# Enable verbose Ansible output
ansible-playbook -vvv playbooks/install_ctrld.yml

# Enable debug logging in services
ansible-playbook playbooks/install_ctrld.yml \
  --extra-vars "ctrld_log_level=debug"
```

## 🤝 Contributing

This automation framework is actively developed for diverse infrastructure needs. Key contribution areas:

### **Platform Support**
- Additional router firmware support
- Cloud provider integrations  
- Container platform automation
- Mobile device management

### **Testing Scenarios**
- Chaos engineering patterns
- Performance benchmarking suites
- Security compliance validation
- Network topology testing

### **Monitoring Integration**
- Prometheus metrics collection
- Grafana dashboard templates
- Alerting rule definitions  
- Log aggregation patterns

## 📋 Development Roadmap

### **Completed ✅**
- [x] Multi-platform system initialization
- [x] Router firmware automation (ASUSWRT-Merlin, OpenWrt, EdgeOS)
- [x] DNS service deployment (Control-D ctrld)
- [x] Configuration management with Ansible Vault
- [x] GitLab CI/CD integration
- [x] Dotfiles synchronization via submodules

### **In Progress 🔄**  
- [ ] Windows Server automation expansion
- [ ] Container orchestration patterns
- [ ] Network security baseline implementation
- [ ] Performance monitoring automation
- [ ] Chaos engineering scenario library

### **Planned 🎯**
- [ ] Kubernetes cluster deployment
- [ ] Cloud provider integration (AWS, GCP, Azure)
- [ ] Infrastructure compliance scanning  
- [ ] Automated backup and disaster recovery
- [ ] Mobile device management (MDM) integration
- [ ] Network topology discovery and mapping

## 📚 Documentation

### **Detailed Guides**
- **[System Initialization](docs/system-init.md)** - Complete setup procedures
- **[Network Device Management](docs/network-devices.md)** - Router and switch automation  
- **[DNS Service Deployment](docs/dns-services.md)** - Control-D and other DNS solutions
- **[Security Hardening](docs/security.md)** - Baseline security implementation
- **[Troubleshooting Guide](docs/troubleshooting.md)** - Common issues and solutions

### **API & Integration**  
- **[Ansible Best Practices](docs/ansible-patterns.md)** - Coding standards and patterns
- **[Vault Management](docs/vault-management.md)** - Secrets and encryption
- **[CI/CD Integration](docs/cicd.md)** - GitLab and automation pipelines
- **[Testing Strategies](docs/testing.md)** - QA and validation approaches

## 🏴‍☠️ Philosophy

> *"Always lots left `todo`, but every deployment should be identical, testable, and recoverable."*

**Gutter Bonez** embodies the principle that infrastructure should be **code**, deployments should be **immutable**, and chaos should be **engineered**. Built for environments where you need to rapidly deploy, test, and validate configurations across diverse computing platforms.

### **Azazel's Infrastructure Commandments:**
1. **Automate everything possible** - Manual is error-prone
2. **Test in production-like chaos** - Chaos finds bugs before users do  
3. **Document failure scenarios** - Learn from every outage
4. **Make recovery faster than breaking** - MTTR > MTTF
5. **Prefer tight feedback loops** over perfect code
6. **Infrastructure as Code** - Version control everything
7. **Immutable deployments** - Replace, don't modify
8. **Security by default** - Harden first, optimize later

## 🎯 Use Cases

### **QA & Testing Engineers**
- Rapid environment provisioning for testing scenarios
- DNS resolution validation across diverse platforms  
- Network device configuration consistency
- Chaos engineering for resilience testing

### **DevOps & SRE Teams**  
- Infrastructure as Code implementation
- Configuration drift detection and remediation
- Automated security baseline enforcement
- Multi-environment deployment pipelines

### **Network Engineers**
- Router and switch configuration management
- Network topology validation and testing
- VLAN and segmentation automation  
- Performance monitoring and optimization

### **Systems Administrators**
- Mass system deployment and configuration
- Security hardening across platforms
- Package management and updates
- User account and access control management

---

*Built with ❤️ for infrastructure engineers who believe that manual deployment is a bug, not a feature.*

**Current Status:** 🚧 **Active Development** - Production ready for core components, expanding platform support and testing scenarios.
