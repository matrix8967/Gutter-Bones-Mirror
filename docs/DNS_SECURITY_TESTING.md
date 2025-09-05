# 🛡️ DNS Security Testing Framework

## Overview

The DNS Security Testing Framework is a comprehensive Ansible-based solution for validating DNS infrastructure security, detecting malicious resolution, and identifying HTTPS interception across diverse network configurations. This framework is specifically designed for QA testing environments and supports Control D DNS integration.

## Features

### 🔍 **Security Testing Capabilities**

- **DNS Baseline Health Checks**: Validate DNS resolution success rates and performance
- **Malicious Domain Blocking**: Test effectiveness of DNS filtering and threat protection
- **DNS Poisoning Detection**: Identify inconsistent responses across multiple resolvers
- **HTTPS Interception Detection**: Detect man-in-the-middle attacks and certificate manipulation
- **Captive Portal Detection**: Identify network authentication requirements
- **DNS-over-HTTPS (DoH) Testing**: Validate secure DNS protocol functionality
- **DNS-over-TLS (DoT) Testing**: Test encrypted DNS transport protocols
- **DNSSEC Validation**: Verify DNS security extension support

### 🎛️ **Control D Integration**

- **Service Health Monitoring**: Monitor ctrld daemon status and performance
- **Policy Enforcement Testing**: Validate DNS filtering rules and categories
- **verify.controld.com Integration**: Automated verification of Control D endpoints
- **Configuration Validation**: Check ctrld.toml configuration integrity

### 📊 **Reporting & Analytics**

- **Interactive HTML Reports**: Comprehensive visual reports with metrics and recommendations
- **JSON Data Export**: Machine-readable test results for integration with CI/CD
- **Performance Metrics**: Response time analysis and latency profiling
- **Security Scoring**: Automated security posture assessment

## Quick Start

### Prerequisites

- Ansible 2.9+ with Python 3.6+
- Target systems with SSH access
- DNS utilities: `dig`, `curl`, `openssl`
- Optional: `kdig` for DoT testing

### Basic Usage

```bash
# Run comprehensive DNS security testing
ansible-playbook playbooks/dns_security_testing.yml -i inventory/example_dns_security.yml

# Test specific security categories
ansible-playbook playbooks/dns_security_testing.yml \
  --extra-vars "dns_security_tests=['baseline','malicious_blocking','performance']"

# Enable Control D integration testing
ansible-playbook playbooks/dns_security_testing.yml \
  --extra-vars "dns_controld_integration=true"

# Fail pipeline on critical security findings
ansible-playbook playbooks/dns_security_testing.yml \
  --extra-vars "dns_security_fail_on_critical=true"
```

### Integration with Main Site Playbook

```bash
# Enable DNS security testing phase in main deployment
ansible-playbook playbooks/site.yml \
  --extra-vars "dns_security_testing=true"
```

## Configuration

### Inventory Configuration

```yaml
# Example host configuration
ubuntu-test-01:
  ansible_host: 192.168.1.100
  ansible_user: azazel
  dns_security_tests:
    - "baseline"
    - "malicious_blocking" 
    - "https_interception"
    - "performance"
  dns_controld_integration: true
  dns_security_fail_on_critical: false
  test_environment: "lab"
```

### Test Categories

| Category | Description | Tests Performed |
|----------|-------------|-----------------|
| `baseline` | Basic DNS health | Resolution success rate, response times |
| `malicious_blocking` | Threat protection | Test malicious domain blocking effectiveness |
| `dns_poisoning` | Cache manipulation | Compare responses across multiple resolvers |
| `https_interception` | Certificate analysis | Detect HTTPS man-in-the-middle attacks |
| `captive_portal` | Network authentication | Test for captive portal presence |
| `secure_dns` | Encrypted protocols | DoH/DoT functionality validation |
| `performance` | Latency analysis | Response time profiling and optimization |
| `dnssec` | DNS security extensions | DNSSEC validation testing |

### Control D Integration

```yaml
# Control D specific configuration
dns_controld_integration: true
controld_endpoints:
  verify: "https://verify.controld.com"
  api: "https://api.controld.com"
```

## Test Scenarios

### Corporate Network Testing

```yaml
dns_security_tests:
  - "baseline"
  - "https_interception"  # Common in corporate environments
  - "captive_portal"
  - "secure_dns"
expected_interception: true  # Corporate proxy/firewall
```

### Home Network Testing

```yaml
dns_security_tests:
  - "baseline"
  - "malicious_blocking"
  - "performance"
expected_interception: false
```

### Public WiFi Testing

```yaml
dns_security_tests:
  - "baseline"
  - "captive_portal"
  - "https_interception"
expected_captive_portal: true
```

### Lab Environment Testing

```yaml
dns_security_tests:
  - "baseline"
  - "dns_poisoning"
  - "malicious_blocking"
  - "secure_dns"
  - "performance"
chaos_testing_enabled: true
```

## Output and Reporting

### Report Locations

```
/tmp/gutter_bonez_dns_security/
├── dns-sec-<timestamp>/
│   ├── dns_security_report.html      # Interactive HTML report
│   ├── dns_security_results.json     # Raw test data
│   ├── comprehensive_report.html     # Detailed analysis
│   ├── ci_variables.env              # GitLab CI integration
│   └── test_summary.json             # Pipeline integration
```

### HTML Report Features

- **Executive Dashboard**: High-level security metrics and status
- **Detailed Test Results**: Comprehensive test breakdowns
- **Performance Analytics**: Response time charts and analysis
- **Security Findings**: Threat detection and recommendations
- **Technical Details**: Raw test data and configuration info

### GitLab CI Integration

The framework automatically generates CI/CD artifacts:

```bash
# Environment variables for pipeline integration
DNS_SECURITY_SUCCESS_RATE=95
DNS_SECURITY_THREAT_BLOCKING=88
DNS_SECURITY_AVG_RESPONSE_TIME=45
DNS_SECURITY_HTTPS_INTERCEPTION=false
DNS_SECURITY_CONTROLD_ACTIVE=true
```

## Security Thresholds

### Default Thresholds

| Metric | Excellent | Good | Warning | Critical |
|--------|-----------|------|---------|----------|
| DNS Success Rate | ≥95% | ≥90% | ≥80% | <80% |
| Threat Blocking | ≥95% | ≥85% | ≥70% | <70% |
| Avg Response Time | ≤50ms | ≤150ms | ≤300ms | >300ms |
| HTTPS Interception | Not Detected | Not Detected | Detected | Detected |

### Custom Thresholds

```yaml
dns_security_thresholds:
  baseline_success_rate: 90
  malicious_blocking_rate: 80
  max_acceptable_response_time: 200
  max_packet_loss: 5
```

## Advanced Features

### Network Environment Detection

Automatically detects and adapts to:
- Corporate networks with proxy/firewall
- Public WiFi with captive portals
- Home networks with basic routing
- Test lab environments

### Chaos Engineering Integration

```yaml
# Enable chaos testing alongside DNS security
chaos_testing_enabled: true
chaos_experiments:
  - network_latency
  - service_disruption
  - packet_loss
```

### Multi-Platform Support

| Platform | Support Level | Features |
|----------|---------------|----------|
| Linux (Debian/Ubuntu) | Full | All test categories |
| Linux (RHEL/Fedora) | Full | All test categories |
| macOS | Partial | Basic tests, limited DoT |
| Windows | Limited | Basic resolution tests |
| Network Devices | Basic | Baseline and performance |

## Troubleshooting

### Common Issues

**DNS Tools Missing**
```bash
# Auto-install on Linux systems
dns_security_tools_install: true
required_packages:
  - dnsutils  # or bind-utils on RHEL
  - curl
  - openssl
```

**Control D Service Not Found**
```bash
# Check ctrld installation
systemctl status ctrld
ls -la /usr/bin/ctrld /etc/ctrld/ctrld.toml
```

**Network Connectivity Issues**
```bash
# Test basic connectivity
ansible all -m ping
dig @8.8.8.8 google.com +short
```

**Permission Errors**
```bash
# Ensure proper SSH key configuration
ansible_ssh_private_key_file: ~/.ssh/id_rsa
ansible_become: true
```

### Debug Mode

```bash
# Enable verbose logging
ansible-playbook playbooks/dns_security_testing.yml -vvv

# Check specific test results
cat /tmp/gutter_bonez_dns_security/*/results.json | jq '.security_summary'
```

### Log Analysis

```bash
# View DNS security test logs
tail -f /var/log/ansible.log | grep dns_security

# Check ctrld service logs
journalctl -u ctrld -f

# Monitor DNS queries
tcpdump -i any port 53 -n
```

## Integration Examples

### GitLab CI Pipeline

```yaml
dns_security_test:
  stage: test
  script:
    - ansible-playbook playbooks/dns_security_testing.yml
      --extra-vars "dns_security_fail_on_critical=true"
  artifacts:
    reports:
      junit: /tmp/gutter_bonez_dns_security/*/test_summary.json
    paths:
      - /tmp/gutter_bonez_dns_security/
    expire_in: 1 week
```

### Scheduled Testing

```bash
# Cron job for daily DNS security testing
0 6 * * * cd /opt/gutter_bonez && ansible-playbook playbooks/dns_security_testing.yml -i inventory/production.yml
```

### Webhook Alerts

```yaml
dns_security_alerts:
  enabled: true
  webhook_url: "https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
  conditions:
    dns_poisoning_detected: true
    low_blocking_rate: true
    https_interception: true
```

## Best Practices

### Testing Strategy

1. **Baseline First**: Always run baseline tests before advanced security testing
2. **Environment-Specific**: Adapt test categories to network environment
3. **Regular Scheduling**: Automate daily/weekly security validation
4. **Threshold Tuning**: Adjust thresholds based on network requirements

### Security Considerations

1. **Test Domain Safety**: Use only safe test domains for malicious blocking tests
2. **Network Impact**: Consider bandwidth usage during performance testing
3. **Service Disruption**: Minimize impact on production DNS services
4. **Data Privacy**: Ensure test results don't contain sensitive information

### Performance Optimization

1. **Parallel Execution**: Enable parallel testing for faster results
2. **Test Scoping**: Run only necessary test categories per environment
3. **Timeout Configuration**: Adjust timeouts based on network latency
4. **Result Caching**: Cache baseline results for comparison

## Contributing

### Adding New Test Categories

1. Extend `roles/dns_security/tasks/main.yml`
2. Update default variables in `roles/dns_security/defaults/main.yml`
3. Add test category documentation
4. Include CI/CD integration support

### Custom Resolvers

```yaml
dns_security_resolvers:
  custom:
    - "your.custom.resolver"
    - "backup.resolver.ip"
```

### Extending Reporting

1. Modify `templates/dns_security_report.j2`
2. Add new metrics to summary generation
3. Update CI/CD variable exports

## Support

### Documentation
- [Gutter Bonez Main README](../README.md)
- [Control D Integration Guide](CONTROLD_INTEGRATION.md)
- [Chaos Engineering Documentation](CHAOS_ENGINEERING.md)

### Troubleshooting Resources
- Check `/tmp/gutter_bonez_dns_security/` for detailed logs
- Review HTML reports for visual diagnostics
- Examine JSON results for programmatic analysis

### Community
- Report issues via GitLab Issues
- Contribute improvements via Merge Requests
- Share test scenarios and configurations

---

**🦴 Gutter Bonez DNS Security Testing Framework**  
*Nowhere to go but up. Always lots left to do.*