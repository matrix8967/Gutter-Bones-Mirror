# Terminal Compatibility Guide

## Overview

The Gutter Bonez DNS Security Testing Framework includes an interactive demo script that automatically detects terminal capabilities and adjusts output accordingly. This guide helps troubleshoot display issues and optimize the experience across different terminals and environments.

## Color Support Detection

The demo script automatically detects terminal capabilities using multiple methods:

1. **TTY Detection**: Checks if output is going to a terminal (`-t 1`)
2. **Color Capability**: Uses `tput colors` to determine color support
3. **Terminal Type**: Examines `$TERM` environment variable
4. **Graceful Fallback**: Switches to plain text when colors aren't supported

## Supported Terminals

### ✅ **Fully Compatible** (Colors + Unicode)

| Terminal | Platform | Notes |
|----------|----------|-------|
| **iTerm2** | macOS | Excellent color support, Unicode rendering |
| **Terminal.app** | macOS | Good compatibility with modern versions |
| **GNOME Terminal** | Linux | Full feature support |
| **Konsole** | Linux | KDE's terminal, excellent compatibility |
| **Alacritty** | Cross-platform | Fast, modern terminal emulator |
| **Kitty** | Cross-platform | GPU-accelerated, full feature support |
| **Hyper** | Cross-platform | Electron-based terminal |
| **Windows Terminal** | Windows | Microsoft's modern terminal |

### ⚠️ **Partial Compatibility** (Limited Colors)

| Terminal | Platform | Limitations |
|----------|----------|-------------|
| **Xterm** | Linux | Basic 8/16 color support |
| **Command Prompt** | Windows | Limited color palette |
| **PuTTY** | Windows | SSH client, basic color support |
| **VSCode Terminal** | Cross-platform | Usually good, depends on theme |

### ❌ **Limited Compatibility** (Plain Text Mode)

| Terminal | Platform | Workaround |
|----------|----------|------------|
| **Screen** | Cross-platform | Use `--no-color` flag |
| **Tmux** (old versions) | Cross-platform | Update tmux or use `--no-color` |
| **CI/CD Environments** | Various | Automatically detected, uses plain text |
| **Serial Consoles** | Hardware | Plain text mode recommended |

## Terminal Configuration

### Check Your Terminal Capabilities

```bash
# Test color support
./scripts/demo_dns_security.sh --test-colors

# Check terminal information
echo "TERM: $TERM"
echo "Colors: $(tput colors 2>/dev/null || echo 'unknown')"
echo "TTY: $([[ -t 1 ]] && echo 'yes' || echo 'no')"
```

### Environment Variables

```bash
# Force color mode (use with caution)
export TERM=xterm-256color

# Force plain text mode
export TERM=dumb

# Disable colors globally
export NO_COLOR=1
```

## Common Issues & Solutions

### Issue: ANSI Escape Codes Visible

**Symptoms**: You see text like `\033[0;32m` instead of colors

**Solutions**:
```bash
# Option 1: Force plain text mode
./scripts/demo_dns_security.sh --no-color

# Option 2: Update terminal environment
export TERM=xterm-256color

# Option 3: Check terminal settings
tput colors  # Should return a number > 0
```

### Issue: Unicode Characters Not Displaying

**Symptoms**: Emojis or special characters appear as `?` or squares

**Solutions**:
```bash
# Check locale settings
locale

# Set UTF-8 encoding
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Use plain text mode as fallback
./scripts/demo_dns_security.sh --no-color
```

### Issue: Terminal Too Narrow

**Symptoms**: Text wrapping, misaligned output

**Solutions**:
```bash
# Check terminal width
tput cols  # Should be at least 80

# Resize terminal or use full-screen mode
# Most demos work best with 100+ column width
```

### Issue: SSH/Remote Terminal Problems

**Symptoms**: Colors work locally but not over SSH

**Solutions**:
```bash
# SSH with proper terminal forwarding
ssh -t user@host

# Set terminal type on remote host
export TERM=$TERM

# Force plain text for SSH sessions
./scripts/demo_dns_security.sh --no-color
```

## Terminal-Specific Recommendations

### macOS Terminal.app
```bash
# Enable 256 color support
# Terminal → Preferences → Profiles → Advanced → 
# Set "Declare terminal as" to "xterm-256color"
```

### Linux Terminals
```bash
# Install full terminfo database
sudo apt-get install ncurses-term  # Debian/Ubuntu
sudo yum install ncurses-term      # RHEL/CentOS

# Verify color support
infocmp $TERM | grep colors
```

### Windows
```bash
# Use Windows Terminal (recommended)
# Or enable VT100 emulation in Command Prompt:
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1

# PowerShell with color support
$Host.UI.RawUI.ForegroundColor = "White"
```

### WSL (Windows Subsystem for Linux)
```bash
# Usually works well with Windows Terminal
# For legacy console, use:
./scripts/demo_dns_security.sh --no-color
```

## CI/CD Environment Compatibility

### GitLab CI
```yaml
variables:
  TERM: "dumb"  # Automatically uses plain text mode

script:
  - ./scripts/demo_dns_security.sh --no-color --quick
```

### GitHub Actions
```yaml
env:
  TERM: dumb

steps:
  - run: ./scripts/demo_dns_security.sh --no-color --quick
```

### Jenkins
```groovy
environment {
    TERM = 'dumb'
}
steps {
    sh './scripts/demo_dns_security.sh --no-color --quick'
}
```

## Testing Terminal Compatibility

### Quick Test Commands

```bash
# Test basic color output
echo -e "\033[31mRed\033[0m \033[32mGreen\033[0m \033[34mBlue\033[0m"

# Test with tput
tput setaf 1; echo "Red"; tput sgr0
tput setaf 2; echo "Green"; tput sgr0

# Test Unicode support
echo "🔧 ✅ ⚠️ ❌ 🛡️"

# Run our color test
./scripts/demo_dns_security.sh --test-colors
```

### Comprehensive Terminal Report

```bash
# Generate terminal compatibility report
cat << EOF
Terminal Compatibility Report
============================

Basic Info:
- TERM: $TERM
- Shell: $SHELL
- TTY: $([[ -t 1 ]] && echo 'yes' || echo 'no')
- Columns: $(tput cols 2>/dev/null || echo 'unknown')
- Lines: $(tput lines 2>/dev/null || echo 'unknown')

Color Support:
- Colors: $(tput colors 2>/dev/null || echo 'unknown')
- Color test: $(echo -e "\033[31mRED\033[32mGREEN\033[34mBLUE\033[0m")

Locale:
- LANG: ${LANG:-not set}
- LC_ALL: ${LC_ALL:-not set}

Platform:
- OS: $(uname -s)
- Version: $(uname -r)
EOF
```

## Best Practices

### For Script Users
1. **Try color mode first**: Most modern terminals support colors
2. **Use `--test-colors`**: Verify display before running tests
3. **Keep terminal wide**: 100+ columns recommended
4. **Update terminal software**: Modern versions have better support
5. **Use `--no-color` for automation**: Consistent output in scripts

### For SSH Users
1. **Use `-t` flag**: `ssh -t user@host`
2. **Forward terminal type**: Terminal settings are preserved
3. **Test on target system**: `./scripts/demo_dns_security.sh --test-colors`
4. **Default to plain text**: `--no-color` for reliable output

### For CI/CD Integration
1. **Set TERM=dumb**: Disables colors automatically
2. **Use explicit flags**: `--no-color` is more reliable than auto-detection
3. **Capture output properly**: Redirect both stdout and stderr
4. **Test locally first**: Verify output format before CI integration

## Troubleshooting Checklist

When experiencing display issues:

- [ ] Run `./scripts/demo_dns_security.sh --test-colors`
- [ ] Check `echo $TERM` output
- [ ] Verify `tput colors` returns a number
- [ ] Test basic color: `echo -e "\033[31mTEST\033[0m"`
- [ ] Try `--no-color` flag
- [ ] Check terminal width: `tput cols`
- [ ] Verify UTF-8 support: `locale | grep UTF-8`
- [ ] Update terminal software if possible
- [ ] Use alternative terminal if available

## Support

If you continue to experience terminal compatibility issues:

1. **Check Documentation**: [README.md](../README.md) and [DNS_SECURITY_TESTING.md](DNS_SECURITY_TESTING.md)
2. **Use Plain Text Mode**: `--no-color` flag works on all terminals
3. **Report Issues**: Include terminal type, OS, and `--test-colors` output
4. **Try Alternative**: Use different terminal emulator if available

---

**Note**: The DNS Security Testing Framework is designed to work across all environments. When in doubt, use `--no-color` for guaranteed compatibility.