# DNS Security Testing Framework - Usage Guide

## Overview

The Gutter Bonez DNS Security Testing Framework is designed to run **from your workstation** against **remote test hosts**. The results (HTML reports, JSON data) are automatically fetched back to your workstation for analysis.

## 🔄 Workflow Types

### 1. Demo/Development Mode (Local Testing)
- **Purpose**: Test the framework itself, development, CI/CD validation
- **Scripts**: `scripts/demo_dns_security.sh`, `scripts/polished_dns_demo.sh`
- **Target**: localhost only
- **Use When**: Framework development, initial setup validation

### 2. Production Mode (Remote Host Testing)
- **Purpose**: Real DNS security testing of remote infrastructure
- **Method**: Direct ansible-playbook execution
- **Target**: Your actual test hosts (routers, servers, endpoints)
- **Use When**: QA testing, security audits, infrastructure validation

## 🎯 Production Usage (Primary Use Case)

### Quick Start

1. **Create your inventory file**:
```ini
# inventory/test_hosts.yml
[routers]
router1 ansible_host=192.168.1.1 ansible_user=admin
router2 ansible_host=10.0.1.1 ansible_user=root

[servers]
server1 ansible_host=192.168.1.100 ansible_user=azazel
server2 ansible_host=192.168.1.101 ansible_user=azazel

[windows_clients]
win-client ansible_host=192.168.1.50 ansible_user=administrator ansible_connection=winrm
```

2. **Run DNS security testing**:
```bash
# Basic health check on all hosts
ansible-playbook playbooks/dns_security_testing.yml \
  --extra-vars '{"test_environment":"production"}' \
  -i inventory/test_hosts.yml

# Test specific host groups
ansible-playbook playbooks/dns_security_testing.yml \
  --extra-vars '{"test_environment":"router_testing"}' \
  --limit routers \
  -i inventory/test_hosts.yml

# Comprehensive security audit
ansible-playbook playbooks/dns_security_testing.yml \
  --extra-vars '{"dns_security_tests":["baseline","malicious_blocking","https_interception","captive_portal"]}' \
  -i inventory/test_hosts.yml
```

3. **View results on your workstation**:
```bash
# Results are automatically saved to:
# /tmp/gutter_bonez_dns_security/dns-security-[timestamp]/

# Open HTML report
firefox /tmp/gutter_bonez_dns_security/dns-security-*/comprehensive_report.html

# View JSON data
cat /tmp/gutter_bonez_dns_security/dns-security-*/results.json | jq .
```

## 🛠️ Common Testing Scenarios

### Router/Network Gear Testing
```bash
# Test ASUSWRT-Merlin routers
ansible-playbook playbooks/dns_security_testing.yml \
  --extra-vars '{"dns_controld_integration":true, "test_environment":"asuswrt_testing"}' \
  --limit routers \
  -i inventory/network_gear.yml
```

### Control D Integration Testing
```bash
# Test hosts running ctrld
ansible-playbook playbooks/dns_security_testing.yml \
  --extra-vars '{"dns_controld_integration":true, "dns_security_tests":["baseline","malicious_blocking"]}' \
  --limit servers \
  -i inventory/controld_hosts.yml
```

### Captive Portal Testing
```bash
# Test for captive portals and HTTPS interception
ansible-playbook playbooks/dns_security_testing.yml \
  --extra-vars '{"dns_security_tests":["captive_portal","https_interception"]}' \
  --limit wireless_clients \
  -i inventory/client_devices.yml
```

### Mixed Environment Audit
```bash
# Comprehensive testing across all device types
ansible-playbook playbooks/dns_security_testing.yml \
  --extra-vars '{"test_environment":"comprehensive_audit"}' \
  -i inventory/all_hosts.yml
```

## 📊 Results & Reports

### Automatic Result Storage
All results are stored on **your workstation** in:
```
/tmp/gutter_bonez_dns_security/dns-security-[timestamp]/
├── comprehensive_report.html    # Rich HTML report with charts
├── results.json                # Raw test data
├── ci_variables.env            # CI/CD integration variables
└── test_summary.json           # Pass/fail summary
```

### Accessing Results
```bash
# Find latest test session
LATEST=$(ls -t /tmp/gutter_bonez_dns_security/ | head -1)

# View HTML report
open "/tmp/gutter_bonez_dns_security/$LATEST/comprehensive_report.html"

# Extract specific data
jq '.baseline_health.success_rate' "/tmp/gutter_bonez_dns_security/$LATEST/results.json"

# CI/CD integration
source "/tmp/gutter_bonez_dns_security/$LATEST/ci_variables.env"
echo "Success rate: $DNS_SECURITY_SUCCESS_RATE%"
```

## ⚙️ Configuration Options

### Test Selection
```bash
# Available test types:
dns_security_tests: [
  "baseline",           # Basic DNS functionality
  "malicious_blocking", # Threat protection
  "https_interception", # Certificate analysis  
  "captive_portal",     # Portal detection
  "secure_dns",         # DoH/DoT testing
  "rebinding_protection", # DNS rebinding tests
  "dnssec"             # DNSSEC validation
]
```

### Control D Integration
```bash
# Enable Control D specific tests
--extra-vars '{"dns_controld_integration":true}'

# Disable Control D tests (default)
--extra-vars '{"dns_controld_integration":false}'
```

### Failure Handling
```bash
# Fail playbook on critical security issues
--extra-vars '{"dns_security_fail_on_critical":true}'

# Continue on critical issues (default for audits)
--extra-vars '{"dns_security_fail_on_critical":false}'
```

## 🔧 Inventory Examples

### SSH Key-Based Authentication
```ini
[test_routers]
asus-ax6000 ansible_host=192.168.1.1 ansible_user=admin ansible_ssh_private_key_file=~/.ssh/router_key
mikrotik-hex ansible_host=192.168.2.1 ansible_user=azazel ansible_ssh_private_key_file=~/.ssh/mikrotik_key

[test_servers]  
pop-os-vm ansible_host=192.168.1.100 ansible_user=azazel
fedora-test ansible_host=192.168.1.101 ansible_user=testuser

[windows_endpoints]
win11-test ansible_host=192.168.1.50 ansible_user=admin ansible_connection=winrm ansible_winrm_transport=ntlm
```

### Per-Host Variables
```ini
[routers:vars]
dns_controld_integration=true

[clients:vars]  
dns_controld_integration=false
dns_security_tests=["baseline","captive_portal"]

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
```

## 🚨 Troubleshooting

### SSH Connection Issues
```bash
# Test connectivity first
ansible all -i inventory/hosts.yml -m ping

# Debug SSH issues
ansible-playbook playbooks/dns_security_testing.yml -i inventory/hosts.yml -vvv
```

### Missing Dependencies
```bash
# The playbook will attempt to install required tools (dig, curl, openssl)
# On locked-down systems, pre-install these tools
```

### Permission Issues
```bash
# Some tests require elevated privileges (for ctrld service checks)
# Add to inventory if needed:
ansible_become=yes
ansible_become_method=sudo
```

## 📈 CI/CD Integration

### GitLab CI Example
```yaml
dns_security_audit:
  stage: test
  script:
    - ansible-playbook playbooks/dns_security_testing.yml 
        --extra-vars '{"test_environment":"ci", "dns_security_fail_on_critical":true}'
        -i inventory/production.yml
  artifacts:
    reports:
      junit: /tmp/gutter_bonez_dns_security/*/test_summary.json
    paths:
      - /tmp/gutter_bonez_dns_security/
    expire_in: 30 days
```

### Extract CI Variables
```bash
# After test completion
source /tmp/gutter_bonez_dns_security/*/ci_variables.env

# Available variables:
# DNS_SECURITY_TEST_SESSION
# DNS_SECURITY_SUCCESS_RATE  
# DNS_SECURITY_THREAT_BLOCKING
# DNS_SECURITY_AVG_RESPONSE_TIME
# DNS_SECURITY_HTTPS_INTERCEPTION
# DNS_SECURITY_CONTROLD_ACTIVE
```

## 💡 Tips & Best Practices

1. **Group similar devices** in inventory for targeted testing
2. **Use SSH keys** for seamless authentication across devices  
3. **Run baseline tests first** before comprehensive audits
4. **Check network connectivity** before running remote tests
5. **Review HTML reports** for detailed analysis and remediation steps
6. **Integrate with your monitoring** using the JSON results
7. **Use `--limit`** to test specific host subsets during development

## 🔍 Demo vs Production

| Aspect | Demo Scripts | Production Usage |
|--------|-------------|------------------|
| **Target** | localhost only | Remote hosts |
| **Purpose** | Framework testing | Real security testing |
| **Inventory** | Auto-generated | Your inventory files |
| **Command** | `./scripts/demo_dns_security.sh` | `ansible-playbook ...` |
| **Results** | Demo data | Real network analysis |

---

**Remember**: The demos are for testing the framework itself. For real DNS security testing of your infrastructure, use the direct ansible-playbook approach with your own inventory files!