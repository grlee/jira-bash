# Jira-Bash Platform Compatibility

This document outlines compatibility considerations for running Jira-Bash on different platforms.

## Operating System Compatibility

Jira-Bash is designed to work across multiple platforms with minimal adjustments.

### Linux

Jira-Bash is fully compatible with Linux distributions. This is the primary development platform and should work without any special configuration.

**Requirements:**
- Bash 4.0 or higher
- curl
- acli (Atlassian CLI)

**Installation Path:**
- Recommended: `/usr/local/bin/` or `~/bin/`

### macOS

Jira-Bash is compatible with macOS, with a few considerations.

**Requirements:**
- Bash 4.0+ (macOS ships with an older version by default)
  - Install newer Bash: `brew install bash`
- curl (pre-installed)
- acli (Atlassian CLI)

**Installation Path:**
- Recommended: `/usr/local/bin/` or `~/bin/`

**macOS-specific notes:**
- Some commands may behave differently on macOS, particularly:
  - `sed` commands may require different syntax
  - Date formatting may vary

### Windows

Jira-Bash can be used on Windows through these environments:

#### Git Bash / MSYS2

**Requirements:**
- Git Bash or MSYS2 environment
- curl
- acli (Atlassian CLI)

**Installation Path:**
- Recommended: `C:/Users/<username>/bin/` or within the Git Bash installation folder

#### Windows Subsystem for Linux (WSL)

Using WSL provides an experience equivalent to native Linux.

**Requirements:**
- WSL with a Linux distribution installed
- Bash 4.0+
- curl
- acli (Atlassian CLI)

**Installation Path:**
- Recommended: `/usr/local/bin/` or `~/bin/` within the WSL environment

#### Cygwin

**Requirements:**
- Cygwin with bash package
- curl package
- acli (Atlassian CLI)

**Installation Path:**
- Recommended: Within the Cygwin installation folder

## Cross-Platform Considerations

When developing or modifying Jira-Bash, consider these cross-platform compatibility guidelines:

### File Paths

Use path construction that works across operating systems:

```bash
# Good - uses environment variables and concatenation
config_dir="${HOME}/.config/jira-cli"

# Avoid hard-coding path separators when possible
# If needed, detect the platform and use appropriate separators
```

### External Dependencies

Minimize external dependencies and check for their existence:

```bash
# Check for required commands
command -v acli &>/dev/null || { echo "acli is required but not installed"; exit 1; }
```

### Text Processing

Be careful with text processing tools that may have different behavior:

- `sed`: macOS uses BSD sed, while Linux uses GNU sed
- `grep`: Some flags work differently across platforms
- `date`: Date formatting options vary between implementations

When possible, use more portable Bash constructs instead of platform-specific external tools.

### Temp Files

Use `mktemp` for creating temporary files, which works across platforms:

```bash
temp_file=$(mktemp) || { echo "Failed to create temp file"; exit 1; }
# Use the temp file
rm -f "$temp_file"  # Clean up
```

### Colors and Terminal

Different terminals support different color codes and capabilities:

```bash
# Check if output is a terminal and supports colors
if [ -t 1 ] && [ -n "$TERM" ] && [ "$TERM" != "dumb" ]; then
    use_colors=true
else
    use_colors=false
fi
```

## Platform-Specific Features

### Linux and macOS

- File permission handling with `chmod` works consistently
- Environment variable usage is similar
- Shell script sourcing works the same way

### Windows Considerations

- Line endings: Windows uses CRLF, while Unix uses LF
- Path separators: Windows uses backslashes, Unix uses forward slashes
- Some shell commands may not be available or work differently
- Environment variables are handled differently in native Windows vs. MSYS/Cygwin environments

## Testing on Different Platforms

Before submitting changes, test on multiple platforms if possible:

1. Test on your primary development platform
2. If you have access to other platforms, test there as well
3. If submitting a pull request, note which platforms you've tested on

## Getting Help with Platform Issues

If you encounter platform-specific issues:

1. Check the documentation for your specific platform
2. Search the project issues for similar problems
3. Open an issue describing the problem, including your OS and environment details