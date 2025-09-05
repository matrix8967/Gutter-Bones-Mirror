#!/usr/bin/env python3
"""
Gutter Bonez Plugin: Network Device Validator
Description: Validates network device configurations and connectivity
Author: Azazel
Category: action
Version: 1.0.0
"""

from ansible.plugins.action import ActionBase
from ansible.errors import AnsibleError, AnsibleActionFail
from ansible.module_utils._text import to_text
from ansible.utils.display import Display
import json
import socket
import subprocess
import time
import re
from datetime import datetime
from typing import Dict, List, Any, Optional, Union

display = Display()

class ActionModule(ActionBase):
    """
    Network Device Configuration Validator

    Validates network device configurations including:
    - Connectivity tests
    - DNS resolution validation
    - Firewall rule verification
    - Interface status checks
    - Configuration compliance
    - Security posture assessment
    """

    TRANSFERS_FILES = False
    _VALID_ARGS = frozenset([
        'device_type', 'config_template', 'validation_rules',
        'timeout', 'retry_count', 'credentials', 'connection_params',
        'compliance_profile', 'security_checks', 'custom_tests',
        'output_format', 'save_results', 'fail_on_error'
    ])

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.validation_results = {
            'timestamp': datetime.now().isoformat(),
            'device_info': {},
            'tests_performed': [],
            'validation_summary': {
                'total_tests': 0,
                'passed_tests': 0,
                'failed_tests': 0,
                'warnings': 0,
                'errors': []
            },
            'detailed_results': {},
            'recommendations': []
        }

    def run(self, tmp=None, task_vars=None):
        """
        Main plugin execution entry point
        """
        if task_vars is None:
            task_vars = {}

        result = super().run(tmp, task_vars)

        try:
            # Parse and validate arguments
            args = self._parse_arguments()

            # Initialize validation context
            self._initialize_validation_context(args, task_vars)

            # Execute validation suite
            validation_results = self._execute_validation_suite(args)

            # Process and format results
            formatted_results = self._format_results(validation_results, args)

            # Save results if requested
            if args.get('save_results', False):
                self._save_results(formatted_results, args)

            # Update result object
            result.update({
                'changed': False,
                'failed': formatted_results['validation_summary']['failed_tests'] > 0 and args.get('fail_on_error', True),
                'validation_results': formatted_results,
                'msg': self._generate_summary_message(formatted_results)
            })

        except Exception as e:
            result['failed'] = True
            result['msg'] = f"Network validation failed: {str(e)}"
            result['exception'] = str(e)
            display.error(f"Network validator error: {str(e)}")

        return result

    def _parse_arguments(self) -> Dict[str, Any]:
        """Parse and validate plugin arguments"""
        args = {}

        # Required arguments
        device_type = self._task.args.get('device_type', 'generic')
        if not device_type:
            raise AnsibleActionFail("device_type is required")
        args['device_type'] = device_type

        # Validation rules
        validation_rules = self._task.args.get('validation_rules', [])
        if isinstance(validation_rules, str):
            validation_rules = [validation_rules]
        args['validation_rules'] = validation_rules or self._get_default_validation_rules(device_type)

        # Optional arguments with defaults
        args.update({
            'config_template': self._task.args.get('config_template'),
            'timeout': int(self._task.args.get('timeout', 30)),
            'retry_count': int(self._task.args.get('retry_count', 3)),
            'credentials': self._task.args.get('credentials', {}),
            'connection_params': self._task.args.get('connection_params', {}),
            'compliance_profile': self._task.args.get('compliance_profile', 'standard'),
            'security_checks': self._task.args.get('security_checks', True),
            'custom_tests': self._task.args.get('custom_tests', []),
            'output_format': self._task.args.get('output_format', 'detailed'),
            'save_results': self._task.args.get('save_results', False),
            'fail_on_error': self._task.args.get('fail_on_error', True)
        })

        return args

    def _initialize_validation_context(self, args: Dict[str, Any], task_vars: Dict[str, Any]):
        """Initialize validation context with device and environment information"""

        # Extract device information from inventory
        device_info = {
            'hostname': task_vars.get('inventory_hostname', 'unknown'),
            'ansible_host': task_vars.get('ansible_host', task_vars.get('inventory_hostname')),
            'device_type': args['device_type'],
            'ansible_system': task_vars.get('ansible_system'),
            'ansible_distribution': task_vars.get('ansible_distribution'),
            'compliance_profile': args['compliance_profile']
        }

        # Add network-specific information
        if 'router' in args['device_type'].lower():
            device_info.update({
                'router_model': task_vars.get('router_model'),
                'firmware_version': task_vars.get('firmware_version'),
                'management_ip': task_vars.get('management_ip')
            })

        self.validation_results['device_info'] = device_info
        display.v(f"Initialized validation context for {device_info['hostname']}")

    def _get_default_validation_rules(self, device_type: str) -> List[str]:
        """Get default validation rules based on device type"""

        base_rules = [
            'connectivity_test',
            'dns_resolution_test',
            'port_accessibility_test'
        ]

        device_specific_rules = {
            'router': [
                'interface_status_check',
                'routing_table_validation',
                'firewall_rules_check',
                'dhcp_service_validation'
            ],
            'firewall': [
                'rule_syntax_validation',
                'policy_compliance_check',
                'logging_configuration_check'
            ],
            'dns_server': [
                'dns_service_validation',
                'zone_file_validation',
                'recursive_query_test'
            ],
            'linux': [
                'service_status_check',
                'configuration_file_validation',
                'security_baseline_check'
            ],
            'windows': [
                'service_status_check',
                'registry_validation',
                'security_policy_check'
            ]
        }

        # Combine base rules with device-specific rules
        rules = base_rules.copy()
        for device_key, specific_rules in device_specific_rules.items():
            if device_key.lower() in device_type.lower():
                rules.extend(specific_rules)
                break

        return rules

    def _execute_validation_suite(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Execute the complete validation suite"""

        validation_rules = args['validation_rules']
        custom_tests = args['custom_tests']

        display.v(f"Executing {len(validation_rules)} validation rules")

        # Execute standard validation rules
        for rule in validation_rules:
            try:
                display.vv(f"Executing validation rule: {rule}")
                test_result = self._execute_validation_rule(rule, args)
                self.validation_results['detailed_results'][rule] = test_result
                self._update_summary_stats(test_result)

            except Exception as e:
                display.warning(f"Validation rule '{rule}' failed: {str(e)}")
                error_result = {
                    'test_name': rule,
                    'status': 'error',
                    'message': str(e),
                    'timestamp': datetime.now().isoformat()
                }
                self.validation_results['detailed_results'][rule] = error_result
                self.validation_results['validation_summary']['errors'].append(str(e))

        # Execute custom tests
        for custom_test in custom_tests:
            try:
                display.vv(f"Executing custom test: {custom_test.get('name', 'unnamed')}")
                test_result = self._execute_custom_test(custom_test, args)
                test_name = custom_test.get('name', f"custom_test_{len(self.validation_results['detailed_results'])}")
                self.validation_results['detailed_results'][test_name] = test_result
                self._update_summary_stats(test_result)

            except Exception as e:
                display.warning(f"Custom test failed: {str(e)}")
                self.validation_results['validation_summary']['errors'].append(str(e))

        # Generate recommendations
        self._generate_recommendations()

        return self.validation_results

    def _execute_validation_rule(self, rule: str, args: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a specific validation rule"""

        rule_methods = {
            'connectivity_test': self._test_connectivity,
            'dns_resolution_test': self._test_dns_resolution,
            'port_accessibility_test': self._test_port_accessibility,
            'interface_status_check': self._check_interface_status,
            'routing_table_validation': self._validate_routing_table,
            'firewall_rules_check': self._check_firewall_rules,
            'dhcp_service_validation': self._validate_dhcp_service,
            'service_status_check': self._check_service_status,
            'configuration_file_validation': self._validate_configuration_files,
            'security_baseline_check': self._check_security_baseline,
            'dns_service_validation': self._validate_dns_service,
            'zone_file_validation': self._validate_zone_files
        }

        if rule in rule_methods:
            return rule_methods[rule](args)
        else:
            display.warning(f"Unknown validation rule: {rule}")
            return {
                'test_name': rule,
                'status': 'skipped',
                'message': f"Unknown validation rule: {rule}",
                'timestamp': datetime.now().isoformat()
            }

    def _test_connectivity(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Test basic network connectivity"""

        device_info = self.validation_results['device_info']
        target_host = device_info.get('ansible_host', device_info.get('hostname'))
        timeout = args.get('timeout', 10)

        start_time = time.time()

        try:
            # Test ICMP connectivity
            result = subprocess.run(
                ['ping', '-c', '3', '-W', str(timeout), target_host],
                capture_output=True,
                text=True,
                timeout=timeout + 5
            )

            response_time = round((time.time() - start_time) * 1000, 2)

            if result.returncode == 0:
                # Extract latency information
                ping_output = result.stdout
                latency_match = re.search(r'time=(\d+\.?\d*)', ping_output)
                avg_latency = float(latency_match.group(1)) if latency_match else None

                return {
                    'test_name': 'connectivity_test',
                    'status': 'passed',
                    'message': f"Connectivity successful to {target_host}",
                    'details': {
                        'target_host': target_host,
                        'response_time_ms': response_time,
                        'avg_latency_ms': avg_latency,
                        'ping_output': ping_output.strip()
                    },
                    'timestamp': datetime.now().isoformat()
                }
            else:
                return {
                    'test_name': 'connectivity_test',
                    'status': 'failed',
                    'message': f"Connectivity failed to {target_host}",
                    'details': {
                        'target_host': target_host,
                        'error_output': result.stderr.strip(),
                        'return_code': result.returncode
                    },
                    'timestamp': datetime.now().isoformat()
                }

        except subprocess.TimeoutExpired:
            return {
                'test_name': 'connectivity_test',
                'status': 'failed',
                'message': f"Connectivity test timed out for {target_host}",
                'details': {'timeout': timeout, 'target_host': target_host},
                'timestamp': datetime.now().isoformat()
            }
        except Exception as e:
            return {
                'test_name': 'connectivity_test',
                'status': 'error',
                'message': f"Connectivity test error: {str(e)}",
                'timestamp': datetime.now().isoformat()
            }

    def _test_dns_resolution(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Test DNS resolution capabilities"""

        test_domains = [
            'verify.controld.com',
            'google.com',
            'cloudflare.com'
        ]

        device_info = self.validation_results['device_info']
        dns_server = device_info.get('ansible_host')

        results = {}
        overall_status = 'passed'
        failed_domains = []

        for domain in test_domains:
            try:
                start_time = time.time()

                # Use dig command for DNS resolution testing
                if dns_server:
                    cmd = ['dig', f'@{dns_server}', domain, '+short', '+time=5']
                else:
                    cmd = ['dig', domain, '+short', '+time=5']

                result = subprocess.run(
                    cmd,
                    capture_output=True,
                    text=True,
                    timeout=10
                )

                response_time = round((time.time() - start_time) * 1000, 2)

                if result.returncode == 0 and result.stdout.strip():
                    results[domain] = {
                        'status': 'resolved',
                        'response': result.stdout.strip(),
                        'response_time_ms': response_time
                    }
                else:
                    results[domain] = {
                        'status': 'failed',
                        'error': result.stderr.strip() if result.stderr else 'No response',
                        'response_time_ms': response_time
                    }
                    failed_domains.append(domain)
                    overall_status = 'failed'

            except subprocess.TimeoutExpired:
                results[domain] = {
                    'status': 'timeout',
                    'error': 'DNS resolution timed out'
                }
                failed_domains.append(domain)
                overall_status = 'failed'
            except Exception as e:
                results[domain] = {
                    'status': 'error',
                    'error': str(e)
                }
                failed_domains.append(domain)
                overall_status = 'failed'

        message = f"DNS resolution test completed"
        if failed_domains:
            message += f" - Failed domains: {', '.join(failed_domains)}"

        return {
            'test_name': 'dns_resolution_test',
            'status': overall_status,
            'message': message,
            'details': {
                'dns_server': dns_server,
                'test_domains': test_domains,
                'results': results,
                'success_rate': f"{((len(test_domains) - len(failed_domains)) / len(test_domains) * 100):.1f}%"
            },
            'timestamp': datetime.now().isoformat()
        }

    def _test_port_accessibility(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Test port accessibility"""

        device_info = self.validation_results['device_info']
        target_host = device_info.get('ansible_host', device_info.get('hostname'))

        # Default ports to test based on device type
        default_ports = {
            'router': [22, 80, 443],
            'firewall': [22, 80, 443, 8080],
            'dns_server': [22, 53, 80, 443],
            'linux': [22, 80, 443],
            'windows': [22, 80, 135, 443, 3389]
        }

        device_type = args.get('device_type', 'generic')
        test_ports = args.get('connection_params', {}).get('test_ports')

        if not test_ports:
            for key, ports in default_ports.items():
                if key.lower() in device_type.lower():
                    test_ports = ports
                    break
            else:
                test_ports = [22, 80, 443]  # Default ports

        results = {}
        open_ports = []
        closed_ports = []

        for port in test_ports:
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                sock.settimeout(5)
                result = sock.connect_ex((target_host, port))
                sock.close()

                if result == 0:
                    results[port] = {'status': 'open', 'accessible': True}
                    open_ports.append(port)
                else:
                    results[port] = {'status': 'closed', 'accessible': False}
                    closed_ports.append(port)

            except Exception as e:
                results[port] = {'status': 'error', 'error': str(e), 'accessible': False}
                closed_ports.append(port)

        # Determine overall status
        critical_ports = [22]  # SSH is usually critical
        critical_open = any(port in open_ports for port in critical_ports)

        if not open_ports:
            status = 'failed'
            message = f"No ports accessible on {target_host}"
        elif not critical_open:
            status = 'warning'
            message = f"Critical ports may be inaccessible on {target_host}"
        else:
            status = 'passed'
            message = f"Port accessibility test completed for {target_host}"

        return {
            'test_name': 'port_accessibility_test',
            'status': status,
            'message': message,
            'details': {
                'target_host': target_host,
                'test_ports': test_ports,
                'open_ports': open_ports,
                'closed_ports': closed_ports,
                'port_results': results,
                'accessibility_rate': f"{(len(open_ports) / len(test_ports) * 100):.1f}%"
            },
            'timestamp': datetime.now().isoformat()
        }

    def _check_interface_status(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Check network interface status (placeholder for router-specific implementation)"""

        return {
            'test_name': 'interface_status_check',
            'status': 'skipped',
            'message': 'Interface status check requires device-specific implementation',
            'details': {
                'note': 'This test should be implemented per device type (ASUSWRT, EdgeOS, etc.)'
            },
            'timestamp': datetime.now().isoformat()
        }

    def _validate_routing_table(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Validate routing table (placeholder)"""

        return {
            'test_name': 'routing_table_validation',
            'status': 'skipped',
            'message': 'Routing table validation requires device-specific implementation',
            'timestamp': datetime.now().isoformat()
        }

    def _check_firewall_rules(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Check firewall rules (placeholder)"""

        return {
            'test_name': 'firewall_rules_check',
            'status': 'skipped',
            'message': 'Firewall rules check requires device-specific implementation',
            'timestamp': datetime.now().isoformat()
        }

    def _validate_dhcp_service(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Validate DHCP service (placeholder)"""

        return {
            'test_name': 'dhcp_service_validation',
            'status': 'skipped',
            'message': 'DHCP service validation requires device-specific implementation',
            'timestamp': datetime.now().isoformat()
        }

    def _check_service_status(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Check service status (placeholder)"""

        return {
            'test_name': 'service_status_check',
            'status': 'skipped',
            'message': 'Service status check requires platform-specific implementation',
            'timestamp': datetime.now().isoformat()
        }

    def _validate_configuration_files(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Validate configuration files (placeholder)"""

        return {
            'test_name': 'configuration_file_validation',
            'status': 'skipped',
            'message': 'Configuration file validation requires platform-specific implementation',
            'timestamp': datetime.now().isoformat()
        }

    def _check_security_baseline(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Check security baseline (placeholder)"""

        return {
            'test_name': 'security_baseline_check',
            'status': 'skipped',
            'message': 'Security baseline check requires platform-specific implementation',
            'timestamp': datetime.now().isoformat()
        }

    def _validate_dns_service(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Validate DNS service (placeholder)"""

        return {
            'test_name': 'dns_service_validation',
            'status': 'skipped',
            'message': 'DNS service validation requires service-specific implementation',
            'timestamp': datetime.now().isoformat()
        }

    def _validate_zone_files(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Validate DNS zone files (placeholder)"""

        return {
            'test_name': 'zone_file_validation',
            'status': 'skipped',
            'message': 'Zone file validation requires DNS server access',
            'timestamp': datetime.now().isoformat()
        }

    def _execute_custom_test(self, test_config: Dict[str, Any], args: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a custom test"""

        test_name = test_config.get('name', 'custom_test')
        test_type = test_config.get('type', 'command')

        if test_type == 'command':
            command = test_config.get('command')
            if not command:
                return {
                    'test_name': test_name,
                    'status': 'error',
                    'message': 'Custom command test requires command parameter',
                    'timestamp': datetime.now().isoformat()
                }

            try:
                result = subprocess.run(
                    command,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=args.get('timeout', 30)
                )

                expected_return_code = test_config.get('expected_return_code', 0)
                status = 'passed' if result.returncode == expected_return_code else 'failed'

                return {
                    'test_name': test_name,
                    'status': status,
                    'message': f"Custom command test completed: {command}",
                    'details': {
                        'command': command,
                        'return_code': result.returncode,
                        'expected_return_code': expected_return_code,
                        'stdout': result.stdout.strip(),
                        'stderr': result.stderr.strip()
                    },
                    'timestamp': datetime.now().isoformat()
                }

            except subprocess.TimeoutExpired:
                return {
                    'test_name': test_name,
                    'status': 'failed',
                    'message': f"Custom command test timed out: {command}",
                    'timestamp': datetime.now().isoformat()
                }
            except Exception as e:
                return {
                    'test_name': test_name,
                    'status': 'error',
                    'message': f"Custom command test error: {str(e)}",
                    'timestamp': datetime.now().isoformat()
                }

        return {
            'test_name': test_name,
            'status': 'skipped',
            'message': f"Unsupported custom test type: {test_type}",
            'timestamp': datetime.now().isoformat()
        }

    def _update_summary_stats(self, test_result: Dict[str, Any]):
        """Update validation summary statistics"""

        summary = self.validation_results['validation_summary']
        summary['total_tests'] += 1

        status = test_result.get('status', 'unknown')

        if status == 'passed':
            summary['passed_tests'] += 1
        elif status == 'failed':
            summary['failed_tests'] += 1
        elif status == 'warning':
            summary['warnings'] += 1

    def _generate_recommendations(self):
        """Generate recommendations based on validation results"""

        recommendations = []
        detailed_results = self.validation_results['detailed_results']

        # Check for connectivity issues
        connectivity_result = detailed_results.get('connectivity_test')
        if connectivity_result and connectivity_result.get('status') == 'failed':
            recommendations.append({
                'category': 'connectivity',
                'priority': 'high',
                'message': 'Network connectivity issues detected. Check network configuration and firewall rules.'
            })

        # Check for DNS resolution issues
        dns_result = detailed_results.get('dns_resolution_test')
        if dns_result and dns_result.get('status') == 'failed':
            recommendations.append({
                'category': 'dns',
                'priority': 'high',
                'message': 'DNS resolution failures detected. Verify DNS server configuration and network connectivity.'
            })

        # Check for port accessibility issues
        port_result = detailed_results.get('port_accessibility_test')
        if port_result and port_result.get('status') in ['failed', 'warning']:
            recommendations.append({
                'category': 'security',
                'priority': 'medium',
                'message': 'Some ports are inaccessible. Review firewall configuration and service status.'
            })

        # Add general recommendations
        failed_tests = self.validation_results['validation_summary']['failed_tests']
        if failed_tests > 0:
            recommendations.append({
                'category': 'general',
                'priority': 'medium',
                'message': f'{failed_tests} validation tests failed. Review detailed results and address configuration issues.'
            })

        self.validation_results['recommendations'] = recommendations

    def _format_results(self, results: Dict[str, Any], args: Dict[str, Any]) -> Dict[str, Any]:
        """Format validation results based on output format"""

        output_format = args.get('output_format', 'detailed')

        if output_format == 'summary':
            return {
                'device_info': results['device_info'],
                'validation_summary': results['validation_summary'],
                'recommendations': results['recommendations']
            }
        elif output_format == 'json':
            return json.loads(json.dumps(results, indent=2))
        else:  # detailed
            return results

    def _save_results(self, results: Dict[str, Any], args: Dict[str, Any]):
        """Save validation results to file"""

        device_hostname = results['device_info'].get('hostname', 'unknown')
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"network_validation_{device_hostname}_{timestamp}.json"

        try:
            with open(filename, 'w') as f:
                json.dump(results, f, indent=2)
            display.v(f"Validation results saved to {filename}")
        except Exception as e:
            display.warning(f"Failed to save validation results: {str(e)}")

    def _generate_summary_message(self, results: Dict[str, Any]) -> str:
        """Generate a summary message for the validation results"""

        summary = results['validation_summary']
        device_hostname = results['device_info'].get('hostname', 'unknown')

        total_tests = summary['total_tests']
        passed_tests = summary['passed_tests']
        failed_tests = summary['failed_tests']
        warnings = summary['warnings']

        if failed_tests > 0:
            status_icon = "❌"
            status_text = "FAILED"
        elif warnings > 0:
            status_icon = "⚠️"
            status_text = "WARNING"
        else:
            status_icon = "✅"
            status_text = "PASSED"

        message = f"{status_icon} Network validation {status_text} for {device_hostname}: "
        message += f"{passed_tests}/{total_tests} tests passed"

        if failed_tests > 0:
            message += f", {failed_tests} failed"
        if warnings > 0:
            message += f", {warnings} warnings"

        return message
