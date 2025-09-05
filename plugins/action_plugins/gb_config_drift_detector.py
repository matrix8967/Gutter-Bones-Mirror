#!/usr/bin/env python3
"""
Gutter Bonez Plugin: Configuration Drift Detector
Description: Detects configuration changes and drift from baseline
Author: Azazel
Category: action
Version: 1.0.0
"""

from ansible.plugins.action import ActionBase
from ansible.errors import AnsibleError, AnsibleActionFail
from ansible.module_utils._text import to_text
from ansible.utils.display import Display
import json
import os
import hashlib
import difflib
import re
import subprocess
from datetime import datetime
from typing import Dict, List, Any, Optional, Union, Tuple
from pathlib import Path

display = Display()

class ActionModule(ActionBase):
    """
    Configuration Drift Detector

    Detects and analyzes configuration drift by comparing:
    - Current system configuration against baseline
    - Configuration files and their checksums
    - System settings and registry values
    - Service configurations and states
    - Network settings and firewall rules
    - Package/software versions
    - Security policies and permissions
    """

    TRANSFERS_FILES = False
    _VALID_ARGS = frozenset([
        'config_baseline', 'current_config', 'config_paths', 'ignore_patterns',
        'drift_threshold', 'check_permissions', 'check_services', 'check_packages',
        'check_network', 'check_firewall', 'custom_checks', 'output_format',
        'save_results', 'generate_remediation', 'fail_on_drift', 'severity_levels'
    ])

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.drift_results = {
            'timestamp': datetime.now().isoformat(),
            'system_info': {},
            'baseline_info': {},
            'drift_analysis': {
                'configuration_files': {},
                'system_settings': {},
                'services': {},
                'packages': {},
                'network': {},
                'firewall': {},
                'permissions': {},
                'custom_checks': {}
            },
            'drift_summary': {
                'total_checks': 0,
                'drift_detected': 0,
                'critical_drift': 0,
                'major_drift': 0,
                'minor_drift': 0,
                'drift_score': 0,
                'compliance_status': 'unknown'
            },
            'remediation_actions': [],
            'recommendations': []
        }

    def run(self, tmp=None, task_vars=None):
        """Main plugin execution entry point"""
        if task_vars is None:
            task_vars = {}

        result = super().run(tmp, task_vars)

        try:
            # Parse and validate arguments
            args = self._parse_arguments()

            # Initialize system and baseline context
            self._initialize_context(args, task_vars)

            # Execute drift detection checks
            self._execute_drift_detection(args)

            # Calculate drift score and compliance status
            self._calculate_drift_metrics()

            # Generate remediation actions
            if args.get('generate_remediation', True):
                self._generate_remediation_actions()

            # Generate recommendations
            self._generate_recommendations()

            # Format and save results
            formatted_results = self._format_results(args)
            if args.get('save_results', False):
                self._save_results(formatted_results, args)

            # Update result object
            result.update({
                'changed': False,
                'failed': self._should_fail(args),
                'config_drift_results': formatted_results,
                'msg': self._generate_summary_message()
            })

        except Exception as e:
            result['failed'] = True
            result['msg'] = f"Configuration drift detection failed: {str(e)}"
            result['exception'] = str(e)
            display.error(f"Config drift detector error: {str(e)}")

        return result

    def _parse_arguments(self) -> Dict[str, Any]:
        """Parse and validate plugin arguments"""
        args = {}

        # Configuration baseline path
        config_baseline = self._task.args.get('config_baseline')
        if config_baseline and not os.path.exists(config_baseline):
            display.warning(f"Baseline configuration path does not exist: {config_baseline}")

        args.update({
            'config_baseline': config_baseline,
            'current_config': self._task.args.get('current_config'),
            'config_paths': self._task.args.get('config_paths', []),
            'ignore_patterns': self._task.args.get('ignore_patterns', []),
            'drift_threshold': float(self._task.args.get('drift_threshold', 5.0)),
            'check_permissions': self._task.args.get('check_permissions', True),
            'check_services': self._task.args.get('check_services', True),
            'check_packages': self._task.args.get('check_packages', True),
            'check_network': self._task.args.get('check_network', True),
            'check_firewall': self._task.args.get('check_firewall', True),
            'custom_checks': self._task.args.get('custom_checks', []),
            'output_format': self._task.args.get('output_format', 'detailed'),
            'save_results': self._task.args.get('save_results', False),
            'generate_remediation': self._task.args.get('generate_remediation', True),
            'fail_on_drift': self._task.args.get('fail_on_drift', False),
            'severity_levels': self._task.args.get('severity_levels', {
                'critical': 90,
                'major': 70,
                'minor': 30
            })
        })

        return args

    def _initialize_context(self, args: Dict[str, Any], task_vars: Dict[str, Any]):
        """Initialize system and baseline context"""

        # System information
        system_info = {
            'hostname': task_vars.get('inventory_hostname', 'unknown'),
            'ansible_system': task_vars.get('ansible_system', 'unknown'),
            'ansible_distribution': task_vars.get('ansible_distribution', 'unknown'),
            'ansible_distribution_version': task_vars.get('ansible_distribution_version', 'unknown'),
            'ansible_architecture': task_vars.get('ansible_architecture', 'unknown'),
            'check_timestamp': datetime.now().isoformat()
        }

        self.drift_results['system_info'] = system_info

        # Baseline information
        baseline_info = {
            'baseline_path': args.get('config_baseline'),
            'baseline_exists': False,
            'baseline_timestamp': None,
            'baseline_checksum': None
        }

        if args.get('config_baseline'):
            baseline_path = args['config_baseline']
            if os.path.exists(baseline_path):
                baseline_info['baseline_exists'] = True
                stat_info = os.stat(baseline_path)
                baseline_info['baseline_timestamp'] = datetime.fromtimestamp(stat_info.st_mtime).isoformat()

                # Calculate baseline checksum
                try:
                    with open(baseline_path, 'rb') as f:
                        baseline_info['baseline_checksum'] = hashlib.sha256(f.read()).hexdigest()
                except Exception as e:
                    display.warning(f"Failed to calculate baseline checksum: {str(e)}")

        self.drift_results['baseline_info'] = baseline_info

        display.v(f"Initialized drift detection context for {system_info['hostname']}")

    def _execute_drift_detection(self, args: Dict[str, Any]):
        """Execute comprehensive drift detection"""
        display.v("Executing configuration drift detection...")

        # Check configuration files
        if args.get('config_paths'):
            self._check_configuration_files(args)

        # Check system settings
        self._check_system_settings(args)

        # Check services
        if args.get('check_services', True):
            self._check_services(args)

        # Check packages
        if args.get('check_packages', True):
            self._check_packages(args)

        # Check network configuration
        if args.get('check_network', True):
            self._check_network_configuration(args)

        # Check firewall rules
        if args.get('check_firewall', True):
            self._check_firewall_configuration(args)

        # Check permissions
        if args.get('check_permissions', True):
            self._check_permissions(args)

        # Execute custom checks
        if args.get('custom_checks'):
            self._execute_custom_checks(args['custom_checks'], args)

    def _check_configuration_files(self, args: Dict[str, Any]):
        """Check configuration file drift"""
        config_paths = args.get('config_paths', [])
        ignore_patterns = args.get('ignore_patterns', [])

        file_drift_results = {
            'checked_files': [],
            'modified_files': [],
            'new_files': [],
            'deleted_files': [],
            'checksum_changes': {},
            'content_diffs': {}
        }

        baseline_path = args.get('config_baseline')
        baseline_data = {}

        # Load baseline data if available
        if baseline_path and os.path.exists(baseline_path):
            try:
                with open(baseline_path, 'r') as f:
                    baseline_data = json.load(f)
            except Exception as e:
                display.warning(f"Failed to load baseline data: {str(e)}")

        # Check each configuration path
        for config_path in config_paths:
            if not os.path.exists(config_path):
                file_drift_results['deleted_files'].append({
                    'path': config_path,
                    'status': 'deleted',
                    'severity': 'major'
                })
                continue

            # Skip if matches ignore patterns
            if self._should_ignore_path(config_path, ignore_patterns):
                continue

            try:
                # Calculate current checksum
                current_checksum = self._calculate_file_checksum(config_path)

                file_info = {
                    'path': config_path,
                    'current_checksum': current_checksum,
                    'modified': False,
                    'drift_type': 'none',
                    'severity': 'minor'
                }

                # Compare with baseline
                baseline_checksum = baseline_data.get('files', {}).get(config_path, {}).get('checksum')

                if baseline_checksum:
                    if current_checksum != baseline_checksum:
                        file_info['modified'] = True
                        file_info['drift_type'] = 'modified'
                        file_info['baseline_checksum'] = baseline_checksum
                        file_info['severity'] = self._determine_file_severity(config_path)

                        # Generate content diff if file is text
                        if self._is_text_file(config_path):
                            baseline_content = baseline_data.get('files', {}).get(config_path, {}).get('content', '')
                            current_content = self._read_file_content(config_path)

                            if baseline_content and current_content:
                                diff = list(difflib.unified_diff(
                                    baseline_content.splitlines(keepends=True),
                                    current_content.splitlines(keepends=True),
                                    fromfile=f"{config_path} (baseline)",
                                    tofile=f"{config_path} (current)",
                                    lineterm=''
                                ))
                                file_drift_results['content_diffs'][config_path] = diff

                        file_drift_results['modified_files'].append(file_info)
                    else:
                        file_drift_results['checked_files'].append(file_info)
                else:
                    # New file (not in baseline)
                    file_info['drift_type'] = 'new'
                    file_info['severity'] = 'minor'
                    file_drift_results['new_files'].append(file_info)

                file_drift_results['checksum_changes'][config_path] = {
                    'baseline': baseline_checksum,
                    'current': current_checksum,
                    'changed': current_checksum != baseline_checksum
                }

            except Exception as e:
                display.warning(f"Failed to check file {config_path}: {str(e)}")

        self.drift_results['drift_analysis']['configuration_files'] = file_drift_results

    def _check_system_settings(self, args: Dict[str, Any]):
        """Check system settings drift"""
        system_settings = {
            'checked_settings': [],
            'changed_settings': [],
            'drift_detected': False
        }

        # Platform-specific system settings checks
        ansible_system = self.drift_results['system_info'].get('ansible_system', '').lower()

        if 'linux' in ansible_system:
            system_settings = self._check_linux_system_settings(args)
        elif 'windows' in ansible_system:
            system_settings = self._check_windows_system_settings(args)
        elif 'darwin' in ansible_system:
            system_settings = self._check_darwin_system_settings(args)

        self.drift_results['drift_analysis']['system_settings'] = system_settings

    def _check_linux_system_settings(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Check Linux-specific system settings"""
        settings_results = {
            'checked_settings': [],
            'changed_settings': [],
            'drift_detected': False
        }

        # Check key system settings
        linux_settings = [
            ('hostname', 'hostname'),
            ('timezone', 'timedatectl show --property=Timezone --value'),
            ('kernel_version', 'uname -r'),
            ('selinux_status', 'getenforce'),
            ('firewall_status', 'systemctl is-active firewalld || systemctl is-active ufw')
        ]

        for setting_name, command in linux_settings:
            try:
                result = subprocess.run(
                    command.split(),
                    capture_output=True,
                    text=True,
                    timeout=10
                )

                if result.returncode == 0:
                    current_value = result.stdout.strip()

                    setting_info = {
                        'name': setting_name,
                        'current_value': current_value,
                        'command': command,
                        'changed': False,
                        'severity': 'minor'
                    }

                    # TODO: Compare with baseline values
                    # For now, just record current values
                    settings_results['checked_settings'].append(setting_info)

            except Exception as e:
                display.warning(f"Failed to check Linux setting {setting_name}: {str(e)}")

        return settings_results

    def _check_windows_system_settings(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Check Windows-specific system settings"""
        return {
            'checked_settings': [],
            'changed_settings': [],
            'drift_detected': False,
            'note': 'Windows system settings check requires PowerShell implementation'
        }

    def _check_darwin_system_settings(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Check macOS-specific system settings"""
        return {
            'checked_settings': [],
            'changed_settings': [],
            'drift_detected': False,
            'note': 'macOS system settings check requires implementation'
        }

    def _check_services(self, args: Dict[str, Any]):
        """Check service configuration drift"""
        service_results = {
            'checked_services': [],
            'changed_services': [],
            'new_services': [],
            'stopped_services': [],
            'drift_detected': False
        }

        # Get list of key services to monitor
        key_services = ['ssh', 'ctrld', 'firewalld', 'systemd-resolved', 'networking']

        for service_name in key_services:
            try:
                # Check service status
                result = subprocess.run(
                    ['systemctl', 'is-active', service_name],
                    capture_output=True,
                    text=True,
                    timeout=5
                )

                service_info = {
                    'name': service_name,
                    'status': result.stdout.strip() if result.returncode == 0 else 'inactive',
                    'changed': False,
                    'severity': 'minor'
                }

                # Check if it's a critical service
                critical_services = ['ssh', 'ctrld', 'networking']
                if service_name in critical_services:
                    service_info['severity'] = 'major' if service_info['status'] != 'active' else 'minor'

                service_results['checked_services'].append(service_info)

                # If service is not active and it's critical, mark as drift
                if service_info['status'] != 'active' and service_name in critical_services:
                    service_results['stopped_services'].append(service_info)
                    service_results['drift_detected'] = True

            except Exception as e:
                display.warning(f"Failed to check service {service_name}: {str(e)}")

        self.drift_results['drift_analysis']['services'] = service_results

    def _check_packages(self, args: Dict[str, Any]):
        """Check package configuration drift"""
        package_results = {
            'checked_packages': [],
            'changed_packages': [],
            'new_packages': [],
            'removed_packages': [],
            'drift_detected': False
        }

        # Get list of installed packages (simplified)
        try:
            ansible_system = self.drift_results['system_info'].get('ansible_system', '').lower()

            if 'linux' in ansible_system:
                # Try different package managers
                package_managers = [
                    ('dpkg', ['dpkg', '-l']),
                    ('rpm', ['rpm', '-qa']),
                    ('pacman', ['pacman', '-Q'])
                ]

                for pm_name, command in package_managers:
                    try:
                        result = subprocess.run(
                            command,
                            capture_output=True,
                            text=True,
                            timeout=30
                        )

                        if result.returncode == 0:
                            package_results['package_manager'] = pm_name
                            package_results['package_count'] = len(result.stdout.strip().split('\n'))

                            # TODO: Compare with baseline package list
                            # For now, just record current state
                            break

                    except Exception:
                        continue

        except Exception as e:
            display.warning(f"Failed to check packages: {str(e)}")

        self.drift_results['drift_analysis']['packages'] = package_results

    def _check_network_configuration(self, args: Dict[str, Any]):
        """Check network configuration drift"""
        network_results = {
            'interfaces': [],
            'routes': [],
            'dns_config': {},
            'changed_interfaces': [],
            'drift_detected': False
        }

        try:
            # Get network interface information
            result = subprocess.run(
                ['ip', 'addr', 'show'],
                capture_output=True,
                text=True,
                timeout=10
            )

            if result.returncode == 0:
                # Parse interface information (simplified)
                interfaces = self._parse_network_interfaces(result.stdout)
                network_results['interfaces'] = interfaces

            # Get routing information
            result = subprocess.run(
                ['ip', 'route', 'show'],
                capture_output=True,
                text=True,
                timeout=10
            )

            if result.returncode == 0:
                network_results['routes'] = result.stdout.strip().split('\n')

            # Get DNS configuration
            dns_config = self._get_dns_configuration()
            network_results['dns_config'] = dns_config

        except Exception as e:
            display.warning(f"Failed to check network configuration: {str(e)}")

        self.drift_results['drift_analysis']['network'] = network_results

    def _check_firewall_configuration(self, args: Dict[str, Any]):
        """Check firewall configuration drift"""
        firewall_results = {
            'firewall_type': 'unknown',
            'status': 'unknown',
            'rules': [],
            'changed_rules': [],
            'drift_detected': False
        }

        try:
            # Try different firewall types
            firewall_commands = [
                ('ufw', ['ufw', 'status', 'verbose']),
                ('firewalld', ['firewall-cmd', '--list-all']),
                ('iptables', ['iptables', '-L', '-n'])
            ]

            for fw_type, command in firewall_commands:
                try:
                    result = subprocess.run(
                        command,
                        capture_output=True,
                        text=True,
                        timeout=15
                    )

                    if result.returncode == 0:
                        firewall_results['firewall_type'] = fw_type
                        firewall_results['status'] = 'active'
                        firewall_results['rules'] = result.stdout.strip().split('\n')
                        break

                except Exception:
                    continue

        except Exception as e:
            display.warning(f"Failed to check firewall configuration: {str(e)}")

        self.drift_results['drift_analysis']['firewall'] = firewall_results

    def _check_permissions(self, args: Dict[str, Any]):
        """Check file permissions drift"""
        permission_results = {
            'checked_paths': [],
            'changed_permissions': [],
            'drift_detected': False
        }

        # Check permissions on critical system files
        critical_paths = [
            '/etc/passwd',
            '/etc/shadow',
            '/etc/sudoers',
            '/etc/ssh/sshd_config',
            '/root',
            '/home'
        ]

        for path in critical_paths:
            if os.path.exists(path):
                try:
                    stat_info = os.stat(path)
                    permission_info = {
                        'path': path,
                        'permissions': oct(stat_info.st_mode)[-3:],
                        'owner_uid': stat_info.st_uid,
                        'group_gid': stat_info.st_gid,
                        'changed': False,
                        'severity': 'major' if path in ['/etc/shadow', '/root'] else 'minor'
                    }

                    permission_results['checked_paths'].append(permission_info)

                except Exception as e:
                    display.warning(f"Failed to check permissions for {path}: {str(e)}")

        self.drift_results['drift_analysis']['permissions'] = permission_results

    def _execute_custom_checks(self, custom_checks: List[Dict], args: Dict[str, Any]):
        """Execute custom drift checks"""
        custom_results = {
            'custom_checks': custom_checks,
            'check_results': [],
            'drift_detected': False
        }

        for check in custom_checks:
            check_name = check.get('name', 'unnamed_check')
            check_type = check.get('type', 'command')

            if check_type == 'command':
                command = check.get('command')
                expected_output = check.get('expected_output')

                if command:
                    try:
                        result = subprocess.run(
                            command,
                            shell=True,
                            capture_output=True,
                            text=True,
                            timeout=30
                        )

                        check_result = {
                            'name': check_name,
                            'command': command,
                            'output': result.stdout.strip(),
                            'return_code': result.returncode,
                            'expected_output': expected_output,
                            'drift_detected': False,
                            'severity': check.get('severity', 'minor')
                        }

                        # Compare with expected output if provided
                        if expected_output is not None:
                            if result.stdout.strip() != expected_output:
                                check_result['drift_detected'] = True
                                custom_results['drift_detected'] = True

                        custom_results['check_results'].append(check_result)

                    except Exception as e:
                        custom_results['check_results'].append({
                            'name': check_name,
                            'error': str(e),
                            'drift_detected': False,
                            'severity': 'minor'
                        })

        self.drift_results['drift_analysis']['custom_checks'] = custom_results

    def _calculate_drift_metrics(self):
        """Calculate overall drift metrics and scores"""
        summary = self.drift_results['drift_summary']
        drift_analysis = self.drift_results['drift_analysis']

        total_checks = 0
        drift_count = 0
        critical_count = 0
        major_count = 0
        minor_count = 0

        # Process each analysis category
        for category, results in drift_analysis.items():
            if isinstance(results, dict):
                # Count checks based on category type
                if category == 'configuration_files':
                    checked = len(results.get('checked_files', []))
                    modified = len(results.get('modified_files', []))
                    new = len(results.get('new_files', []))
                    deleted = len(results.get('deleted_files', []))

                    total_checks += checked + modified + new + deleted
                    drift_count += modified + new + deleted

                    # Count by severity
                    for file_info in results.get('modified_files', []) + results.get('new_files', []) + results.get('deleted_files', []):
                        severity = file_info.get('severity', 'minor')
                        if severity == 'critical':
                            critical_count += 1
                        elif severity == 'major':
                            major_count += 1
                        else:
                            minor_count += 1

                elif category == 'services':
                    total_checks += len(results.get('checked_services', []))
                    drift_count += len(results.get('stopped_services', []))

                    for service in results.get('stopped_services', []):
                        severity = service.get('severity', 'minor')
                        if severity == 'major':
                            major_count += 1
                        else:
                            minor_count += 1

                elif category == 'permissions':
                    total_checks += len(results.get('checked_paths', []))
                    changed = len(results.get('changed_permissions', []))
                    drift_count += changed

                    for perm in results.get('changed_permissions', []):
                        severity = perm.get('severity', 'minor')
                        if severity == 'major':
                            major_count += 1
                        else:
                            minor_count += 1

                elif category == 'custom_checks':
                    check_results = results.get('check_results', [])
                    total_checks += len(check_results)

                    for check in check_results:
                        if check.get('drift_detected', False):
                            drift_count += 1
                            severity = check.get('severity', 'minor')
                            if severity == 'critical':
                                critical_count += 1
                            elif severity == 'major':
                                major_count += 1
                            else:
                                minor_count += 1

        # Update summary
        summary.update({
            'total_checks': total_checks,
            'drift_detected': drift_count,
            'critical_drift': critical_count,
            'major_drift': major_count,
            'minor_drift': minor_count
        })

        # Calculate drift score (0-100, where 100 is no drift)
        if total_checks > 0:
            drift_percentage = (drift_count / total_checks) * 100
            drift_score = max(0, 100 - drift_percentage)

            # Weight by severity
            severity_weight = (critical_count * 3 + major_count * 2 + minor_count * 1)
            if severity_weight > 0:
                drift_score = max(0, drift_score - (severity_weight * 5))
        else:
            drift_score = 100

        summary['drift_score'] = round(drift_score, 1)

        # Determine compliance status
        if drift_score >= 95:
            summary['compliance_status'] = 'excellent'
        elif drift_score >= 85:
            summary['compliance_status'] = 'good'
        elif drift_score >= 70:
            summary['compliance_status'] = 'moderate'
        elif drift_score >= 50:
            summary['compliance_status'] = 'poor'
        else:
            summary['compliance_status'] = 'critical'

    def _generate_remediation_actions(self):
        """Generate remediation actions for detected drift"""
        remediation_actions = []
        drift_analysis = self.drift_results['drift_analysis']

        # Remediation for modified configuration files
        config_files = drift_analysis.get('configuration_files', {})
        for modified_file in config_files.get('modified_files', []):
            remediation_actions.append({
                'category': 'configuration',
                'action': 'restore_file',
                'target': modified_file['path'],
                'description': f"Restore {modified_file['path']} from baseline configuration",
                'priority': modified_file.get('severity', 'minor'),
                'command': f"# Restore file from baseline: cp baseline/{modified_file['path']} {modified_file['path']}"
            })

        # Remediation for stopped services
        services = drift_analysis.get('services', {})
        for stopped_service in services.get('stopped_services', []):
            remediation_actions.append({
                'category': 'services',
                'action': 'start_service',
                'target': stopped_service['name'],
                'description': f"Start service {stopped_service['name']}",
                'priority': stopped_service.get('severity', 'minor'),
                'command': f"systemctl start {stopped_service['name']} && systemctl enable {stopped_service['name']}"
            })

        # Remediation for permission changes
        permissions = drift_analysis.get('permissions', {})
        for perm_change in permissions.get('changed_permissions', []):
            remediation_actions.append({
                'category': 'permissions',
                'action': 'fix_permissions',
                'target': perm_change['path'],
                'description': f"Fix permissions for {perm_change['path']}",
                'priority': perm_change.get('severity', 'minor'),
                'command': f"# Review and fix permissions: chmod <correct_perms> {perm_change['path']}"
            })

        self.drift_results['remediation_actions'] = remediation_actions

    def _generate_recommendations(self):
        """Generate recommendations based on drift analysis"""
        recommendations = []
        drift_summary = self.drift_results['drift_summary']

        # Overall drift recommendations
        drift_score = drift_summary.get('drift_score', 100)
        if drift_score < 70:
            recommendations.append({
                'category': 'critical',
                'priority': 'high',
                'message': f'Significant configuration drift detected (score: {drift_score:.1f}). Immediate review and remediation required.'
            })
        elif drift_score < 85:
            recommendations.append({
                'category': 'moderate',
                'priority': 'medium',
                'message': f'Moderate configuration drift detected (score: {drift_score:.1f}). Review and address drift items.'
            })

        # Specific recommendations based on drift types
        if drift_summary.get('critical_drift', 0) > 0:
            recommendations.append({
                'category': 'security',
                'priority': 'critical',
                'message': f"{drift_summary['critical_drift']} critical configuration changes detected. Immediate security review required."
            })

        if drift_summary.get('major_drift', 0) > 0:
            recommendations.append({
                'category': 'configuration',
                'priority': 'high',
                'message': f"{drift_summary['major_drift']} major configuration changes detected. Review and remediate promptly."
            })

        self.drift_results['recommendations'] = recommendations

    # Helper methods
    def _calculate_file_checksum(self, file_path: str) -> str:
        """Calculate SHA256 checksum of file"""
        try:
            with open(file_path, 'rb') as f:
                return hashlib.sha256(f.read()).hexdigest()
        except Exception:
            return ""

    def _should_ignore_path(self, path: str, ignore_patterns: List[str]) -> bool:
        """Check if path should be ignored based on patterns"""
        for pattern in ignore_patterns:
            if re.search(pattern, path):
                return True
        return False

    def _determine_file_severity(self, file_path: str) -> str:
        """Determine severity of file changes"""
        critical_files = ['/etc/passwd', '/etc/shadow', '/etc/sudoers', '/root/.ssh/']
        major_files = ['/etc/ssh/', '/etc/systemd/', '/etc/network/']

        for critical in critical_files:
            if critical in file_path:
                return 'critical'

        for major in major_files:
            if major in file_path:
                return 'major'

        return 'minor'

    def _is_text_file(self, file_path: str) -> bool:
        """Check if file is text file"""
        try:
            with open(file_path, 'rb') as f:
                chunk = f.read(1024)
                return b'\0' not in chunk
        except Exception:
            return False

    def _read_file_content(self, file_path: str) -> str:
        """Read file content as string"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                return f.read()
        except Exception:
            return ""

    def _parse_network_interfaces(self, ip_output: str) -> List[Dict[str, Any]]:
        """Parse network interface information"""
        interfaces = []
        current_interface = None

        for line in ip_output.split('\n'):
            line = line.strip()
            if re.match(r'^\d+:', line):
                if current_interface:
                    interfaces.append(current_interface)

                interface_match = re.match(r'^\d+:\s+([^:]+):', line)
                if interface_match:
                    current_interface = {
                        'name': interface_match.group(1),
                        'addresses': [],
                        'status': 'UP' if 'UP' in line else 'DOWN'
                    }
            elif current_interface and 'inet' in line:
                addr_match = re.search(r'inet\s+([^\s]+)', line)
                if addr_match:
                    current_interface['addresses'].append(addr_match.group(1))

        if current_interface:
            interfaces.append(current_interface)

        return interfaces

    def _get_dns_configuration(self) -> Dict[str, Any]:
        """Get DNS configuration"""
        dns_config = {
            'nameservers': [],
            'search_domains': [],
            'config_file': '/etc/resolv.conf'
        }

        try:
            with open('/etc/resolv.conf', 'r') as f:
                for line in f:
                    line = line.strip()
                    if line.startswith('nameserver'):
                        dns_config['nameservers'].append(line.split()[1])
                    elif line.startswith('search'):
                        dns_config['search_domains'].extend(line.split()[1:])
        except Exception:
            pass

        return dns_config

    def _format_results(self, args: Dict[str, Any]) -> Dict[str, Any]:
        """Format results based on output format"""
        output_format = args.get('output_format', 'detailed')

        if output_format == 'summary':
            return {
                'system_info': self.drift_results['system_info'],
                'drift_summary': self.drift_results['drift_summary'],
                'recommendations': self.drift_results['recommendations']
            }
        elif output_format == 'remediation':
            return {
                'drift_summary': self.drift_results['drift_summary'],
                'remediation_actions': self.drift_results['remediation_actions'],
                'recommendations': self.drift_results['recommendations']
            }
        else:  # detailed
            return self.drift_results

    def _save_results(self, results: Dict[str, Any], args: Dict[str, Any]):
        """Save drift detection results to file"""
        hostname = results.get('system_info', {}).get('hostname', 'unknown')
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"config_drift_{hostname}_{timestamp}.json"

        try:
            with open(filename, 'w') as f:
                json.dump(results, f, indent=2)
            display.v(f"Configuration drift results saved to {filename}")
        except Exception as e:
            display.warning(f"Failed to save drift results: {str(e)}")

    def _should_fail(self, args: Dict[str, Any]) -> bool:
        """Determine if task should fail based on drift results"""
        if not args.get('fail_on_drift', False):
            return False

        drift_summary = self.drift_results['drift_summary']
        drift_threshold = args.get('drift_threshold', 5.0)

        # Fail if drift score is below threshold
        drift_score = drift_summary.get('drift_score', 100)
        if drift_score < (100 - drift_threshold):
            return True

        # Fail if critical drift detected
        if drift_summary.get('critical_drift', 0) > 0:
            return True

        return False

    def _generate_summary_message(self) -> str:
        """Generate summary message"""
        drift_summary = self.drift_results['drift_summary']
        system_info = self.drift_results['system_info']

        hostname = system_info.get('hostname', 'unknown')
        drift_score = drift_summary.get('drift_score', 100)
        compliance_status = drift_summary.get('compliance_status', 'unknown')
        total_drift = drift_summary.get('drift_detected', 0)

        if drift_score >= 95:
            status_icon = "✅"
            status_text = "EXCELLENT"
        elif drift_score >= 85:
            status_icon = "✅"
            status_text = "GOOD"
        elif drift_score >= 70:
            status_icon = "⚠️"
            status_text = "MODERATE"
        elif drift_score >= 50:
            status_icon = "❌"
            status_text = "POOR"
        else:
            status_icon = "🚨"
            status_text = "CRITICAL"

        message = f"{status_icon} Configuration drift {status_text} for {hostname}: "
        message += f"Score: {drift_score:.1f}%, Status: {compliance_status.upper()}, "
        message += f"Drift items: {total_drift}"

        return message
