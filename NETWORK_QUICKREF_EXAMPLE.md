# 🌐 Network Quick Reference - Example

**Domain:** `.example.local` | **Primary Gateway:** EdgeRouter 8 Pro (192.168.1.1)

## 🏗️ Network Topology

| Subnet | VLAN | Purpose | Gateway | Isolation |
|--------|------|---------|---------|-----------|
| `192.168.1.0/24` | 10 | **Production** | 192.168.1.1 | Full Internet |
| `192.168.10.0/24` | 20 | **Lab/Testing** | 192.168.10.1 | Isolated |
| `192.168.20.0/24` | 30 | **DMZ/Guest** | 192.168.20.1 | Restricted |

## 🖥️ Device Layout

### Production Network (192.168.1.0/24)
- `192.168.1.1` - **EdgeRouter 8 Pro** (Primary Gateway)
- `192.168.1.53` - **dns-primary.example.local** (Primary DNS/ctrld)
- `192.168.1.40` - **monitoring.example.local** (Prometheus/Grafana)
- `192.168.1.30` - **unifi-controller.example.local** (WiFi Management)
- `192.168.1.10-11` - **prod-server-01/02.example.local** (Production Servers)
- `192.168.1.100-101` - **QA/Dev Workstations**

### Lab Environment (192.168.10.0/24)
- `192.168.10.1` - **ASUS GT-AX6000** (Lab Router Testing)
- `192.168.10.2` - **Netgear R7000** (FreshTomato Testing)
- `192.168.10.10-12` - **lab-server-01/02/03.example.local** (Ubuntu/Debian/Fedora)
- `192.168.10.20` - **lab-ad-dc.example.local** (Windows Server 2022 AD)
- `192.168.10.21` - **lab-win11-01.example.local** (Windows 11 Testing)

## 🚀 Quick Commands

### DNS Testing
```bash
# Test local DNS resolution
dig @192.168.1.53 gateway.example.local

# Test Control D resolution
dig @192.168.1.53 verify.controld.com

# Test malware blocking
dig @192.168.1.53 malware.testcategory.com

# Test Control D connectivity
curl https://verify.controld.com/json

# Check ctrld service status
systemctl status ctrld
```

### SSH Access
```bash
# EdgeRouter 8 Pro
ssh admin@192.168.1.1

# Production servers
ssh user@192.168.1.10  # prod-server-01
ssh user@192.168.1.11  # prod-server-02

# Lab environment
ssh user@192.168.10.10  # lab-server-01
```

### Port Forwards (Example)
- `2201/tcp` → `192.168.1.10:22` (SSH to prod-server-01)
- `8443/tcp` → `192.168.1.30:8443` (UniFi Controller)

## 🧪 Testing & QA

### DNS Security Testing
```bash
# Run comprehensive DNS security tests
ansible-playbook playbooks/dns_security_testing.yml

# Test specific security categories
ansible-playbook playbooks/dns_security_testing.yml \
  --extra-vars "dns_security_tests=['baseline','malicious_blocking']"

# Run with Control D integration
ansible-playbook playbooks/dns_security_testing.yml \
  --extra-vars "dns_controld_integration=true"
```

### Web Interfaces
- **Prometheus:** http://192.168.1.40:9090
- **Grafana:** http://192.168.1.40:3000
- **UniFi Controller:** https://192.168.1.30:8443

### Log Locations
```bash
# Control D logs
tail -f /var/log/ctrld/ctrld.log

# System logs
journalctl -u ctrld -f

# DNS query logs (if enabled)
tail -f /var/log/ctrld/queries.log

# Ansible test results
ls -la /tmp/gutter_bonez_*/
```

## 🔧 Network Testing

### VLAN Isolation Testing
```bash
# Test VLAN isolation
ping 192.168.10.10  # Should fail from production network

# Check routing table
ip route show
show ip route  # EdgeRouter

# Test inter-VLAN blocking
traceroute 192.168.20.10  # Should be blocked
```

### Router Management
```bash
# Connect to EdgeRouter
ssh admin@192.168.1.1

# Show interface status
show interfaces

# Check firewall rules
show firewall
show firewall statistics

# Monitor system resources
show system processes
show system storage
```

## 🛡️ Security & Monitoring

### Firewall Testing
```bash
# Test firewall rules from different VLANs
nmap -p 80,443,22 192.168.1.10

# Check blocked ports
nmap -p 1-1000 192.168.10.10

# Verify DNS filtering
dig @192.168.1.53 ads.testcategory.com
```

### Performance Monitoring
```bash
# Network performance testing
iperf3 -c 192.168.1.10

# DNS response time testing
dig @192.168.1.53 example.com | grep "Query time"

# Bandwidth monitoring
vnstat -i eth0
```

## 🔑 SSH Configuration Example

```bash
# ~/.ssh/config example
Host gateway
    HostName 192.168.1.1
    User admin
    Port 22

Host prod-*
    HostName 192.168.1.%h
    User admin
    ProxyJump gateway

Host lab-*
    HostName 192.168.10.%h
    User user
```

## 📊 Gutter Bonez Integration

### Ansible Inventory Groups
```ini
[gateways]
gateway ansible_host=192.168.1.1 ansible_user=admin

[production_servers]
prod-server-01 ansible_host=192.168.1.10
prod-server-02 ansible_host=192.168.1.11

[lab_servers]
lab-server-01 ansible_host=192.168.10.10
lab-server-02 ansible_host=192.168.10.11
```

### Common Playbook Commands
```bash
# System initialization
ansible-playbook playbooks/Init.yml -i inventory/hosts

# DNS service deployment
ansible-playbook playbooks/install_ctrld.yml -i inventory/hosts

# Security hardening
ansible-playbook playbooks/Firewall.yml -i inventory/hosts

# Comprehensive deployment
ansible-playbook playbooks/site.yml -i inventory/hosts
```

---

**🦴 Gutter Bonez Infrastructure**  
*Nowhere to go but up. Always lots left to do.*

> **Note**: This is an example configuration. Replace IP addresses, hostnames, and credentials with your actual values. Ensure sensitive information is properly secured using Ansible Vault.