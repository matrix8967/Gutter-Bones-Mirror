# Gutter Bonez Documentation

> **Ansible roles and playbooks for deployment and chaos engineering**

## 📁 Documentation Structure

This documentation is organized into logical categories to help you find what you need quickly:

- **[`guides/`](./guides/)** - Step-by-step tutorials and implementation guides
- **[`references/`](./references/)** - Quick references, checklists, and lookup docs  
- **[`summaries/`](./summaries/)** - Enhancement summaries and fix documentation

## 🚀 Getting Started

For new users, start with these core documents:

1. **[Main README](../README.md)** - Project overview and setup
2. **[Usage Guide](../USAGE.md)** - Basic usage instructions
3. **[Security Policy](../SECURITY.md)** - Security guidelines and policies

## 📖 Implementation Guides

Step-by-step tutorials for complex implementations:

| Guide | Description |
|-------|-------------|
| [ControlD Parsing Fix](./guides/controld-parsing-fix.md) | Fix ControlD parsing issues |
| [DNS Security Fixes](./guides/dns-security-fixes.md) | DNS security vulnerability fixes |
| [DNS Security Implementation](./guides/dns-security-implementation.md) | Complete DNS security setup |
| [Testing Guide](./guides/testing-guide.md) | Testing procedures and best practices |
| [Vault Upgrade Guide](./guides/vault-upgrade-guide.md) | Ansible Vault upgrade procedures |

## 🔍 Quick References

Fast lookup documentation and checklists:

| Reference | Description |
|-----------|-------------|
| [Darkfort Quick Reference](./references/darkfort-quickref.md) | Darkfort network quick reference |
| [Network Quick Reference Example](./references/network-quickref-example.md) | Network configuration examples |
| [Vault Strings Reference](./references/vault-strings.md) | Vault string configurations |
| [Pre-commit Checklist](./references/pre-commit-checklist.md) | Pre-commit verification steps |

## 📋 Project Documentation

Current project documentation (also in main docs folder):

| Document | Description |
|----------|-------------|
| [Darkfort Network](./DARKFORT_NETWORK.md) | Darkfort network configuration |
| [DNS Security Testing](./DNS_SECURITY_TESTING.md) | DNS security testing procedures |
| [Inventory Comparison](./INVENTORY_COMPARISON.md) | Inventory management comparison |
| [Security Management](./SECURITY_MANAGEMENT.md) | Security management procedures |
| [Terminal Compatibility](./TERMINAL_COMPATIBILITY.md) | Terminal compatibility notes |

## 📊 Summaries & Changelogs

Historical summaries and fix documentation:

| Summary | Description |
|---------|-------------|
| [Enhancement Summary](./summaries/enhancement-summary.md) | Recent enhancements and improvements |
| [GitLab CI Fix Summary](./summaries/gitlab-ci-fix-summary.md) | CI/CD pipeline fixes and updates |

## 🤝 Contributing

When adding new documentation:

1. **Guides** → Complex, multi-step tutorials go in `guides/`
2. **References** → Quick lookups, checklists, and examples go in `references/`
3. **Summaries** → Change logs and fix summaries go in `summaries/`
4. Use kebab-case for filenames (e.g., `my-new-guide.md`)
5. Update this README index when adding new files

## 🏷️ File Naming Convention

- **Guides**: `[topic]-[action].md` (e.g., `dns-security-implementation.md`)
- **References**: `[topic]-[type].md` (e.g., `network-quickref.md`)
- **Summaries**: `[topic]-summary.md` (e.g., `enhancement-summary.md`)

---

> 💡 **Tip**: Use your browser's search (Ctrl+F) to quickly find specific topics in this index.