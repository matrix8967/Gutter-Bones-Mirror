# Gutter Bonez Test Scripts & Playbooks

This directory contains testing utilities and playbooks for the Gutter Bonez infrastructure automation project.

## 🚀 Quick Start

### Basic Connectivity Testing

```bash
# Test all systems
./scripts/quick_test.sh

# Test specific groups
./scripts/quick_test.sh production
./scripts/quick_test.sh network
./scripts/quick_test.sh remote

# Check inventory syntax
./scripts/quick_test.sh inventory

# List all hosts
./scripts/quick_test.sh list
```

### Detailed Connectivity Testing

```bash
# Comprehensive connectivity test with detailed output
./scripts/test_connectivity.sh

# Test specific group
./scripts/test_connectivity.sh production_linux
./scripts/test_connectivity.sh asus_routers
```

## 📋 Available Test Scripts

### `quick_test.sh`
Fast connectivity and functionality tests with colored output.

**Options:**
- `ping` - Quick ping test for all groups
- `production` - Test production subnet hosts
- `network` - Test network devices (routers, APs)
- `remote` - Test remote hosts via jumphost
- `dns` - Test DNS resolution and ctrld status
- `info` - Quick system information
- `inventory` - Check inventory syntax
- `list` - List all hosts by group
- `all` - Run all connectivity tests (default)

### `test_connectivity.sh`
Comprehensive SSH connectivity testing with detailed per-host results.

**Features:**
- Tests all inventory groups
- Special handling for network devices
- Color-coded success/failure output
- Individual host status reporting

## 📖 Available Playbooks

### `playbooks/tests/connectivity_test.yml`
Comprehensive connectivity test playbook that:
- Tests SSH connectivity to all Linux systems
- Validates sudo access
- Tests network device accessibility
- Generates detailed connectivity reports

**Usage:**
```bash
ansible-playbook -i inventory/Inventory01.ini playbooks/tests/connectivity_test.yml
```

### `playbooks/tests/system_info.yml`
Detailed system information gathering playbook that:
- Collects comprehensive system facts
- Generates individual host reports
- Tests ctrld status and DNS configuration
- Creates network device information reports
- Generates infrastructure summary

**Usage:**
```bash
ansible-playbook -i inventory/Inventory01.ini playbooks/tests/system_info.yml
```

**Output:** Reports saved to `/tmp/gutter_bonez_reports/`

## 🎯 Common Use Cases

### Daily Health Check
```bash
# Quick morning health check
./scripts/quick_test.sh production

# Check DNS and ctrld status
./scripts/quick_test.sh dns
```

### New Host Verification
```bash
# Test specific host connectivity
ansible NewHost -i inventory/Inventory01.ini -m ping

# Gather system info for new host
ansible NewHost -i inventory/Inventory01.ini -m setup
```

### Network Device Management
```bash
# Test all routers
./scripts/quick_test.sh network

# Check specific ASUS router
ansible AsusGTAX6000 -i inventory/Inventory01.ini -m raw -a "uname -a"

# Check Ubiquiti device status
ansible Edgerouter -i inventory/Inventory01.ini -m raw -a "show version"
```

### Remote Systems Testing
```bash
# Test systems via Styx jumphost
./scripts/quick_test.sh remote

# Test specific remote host
ansible DeadSea -i inventory/Inventory01.ini -m ping
```

## 🔧 Inventory Groups Reference

### Linux Systems
- `production_linux` - Local subnet Linux hosts
- `apple` - Mac systems  
- `vmnet` - VM network hosts

### Network Devices
- `ubiquiti_routers` - EdgeRouter, ERX devices
- `asus_routers` - ASUSWRT-Merlin routers
- `other_routers` - MikroTik, R7000, etc.
- `unifi_devices` - UniFi access points

### Remote Systems  
- `styx_internal` - Systems via Styx jumphost
- `vultr_hosts` - Vultr cloud instances
- `linode_hosts` - Linode cloud instances

### Logical Groups
- `linux` - All Linux-based systems
- `network_devices` - All network infrastructure
- `production` - Local production subnet
- `remote` - All remote systems

## 🛠️ Troubleshooting

### Common Issues

**SSH Connection Failures:**
```bash
# Check SSH config
ssh -T RPi5

# Test with verbose output
ansible RPi5 -i inventory/Inventory01.ini -m ping -vvv
```

**Network Device Access:**
```bash
# Test raw SSH to router
ssh Matrix@10.10.10.1 -p 8967

# Check router-specific commands
ansible Edgerouter -i inventory/Inventory01.ini -m raw -a "show version"
```

**Jumphost Issues:**
```bash
# Test direct connection to Styx
ssh Styx

# Test proxy command
ssh -o ProxyCommand="ssh -W %h:%p -q Styx" DeadSea
```

### Debug Mode
Enable debug output for detailed troubleshooting:
```bash
export ANSIBLE_DEBUG=True
ansible-playbook -vvv [playbook]
```

## 📁 File Structure

```
gutter_bonez/
├── scripts/
│   ├── README.md              # This file
│   ├── quick_test.sh          # Fast connectivity tests
│   └── test_connectivity.sh   # Detailed connectivity tests
├── playbooks/tests/
│   ├── connectivity_test.yml  # Comprehensive connectivity playbook  
│   └── system_info.yml        # System information gathering
├── templates/
│   └── system_report.j2       # System report template
└── inventory/
    └── Inventory01.ini        # Main inventory file
```

## 🔍 Output Examples

### Quick Test Success
```
[TEST] Quick ping test for group: production_linux
[SUCCESS] ✓ RPi5
[SUCCESS] ✓ Darlene  
[SUCCESS] ✓ LittleHorn
```

### System Info Reports
Reports generated in `/tmp/gutter_bonez_reports/`:
- `hostname_system_report_timestamp.txt` - Individual system reports
- `hostname_network_device_timestamp.txt` - Network device info
- `infrastructure_summary_timestamp.txt` - Overall summary

---

**Need help?** Check the script help: `./scripts/quick_test.sh help`
