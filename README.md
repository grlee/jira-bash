# Jira-Bash

A powerful Bash CLI wrapper for Jira that provides comprehensive terminal-based access to Jira functionality. This single-file script handles tickets, sprints, epics and more through a consistent command-line interface.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- 🎫 **Complete Ticket Management**: View, create, comment, transition, and assign tickets
- 🏃 **Sprint Operations**: List, view, create, and manage sprints
- 🏔️ **Epic Support**: Create and manage epics and their child issues
- 🔍 **JQL Support**: Run custom JQL queries directly from the command line
- 🔧 **Configurable**: Easy setup and configuration management
- 📃 **Rich Output Formats**: Choose between plain text, JSON, or CSV output

## Prerequisites

- Bash 4.0+
- [Atlassian CLI (acli)](https://developer.atlassian.com/cloud/acli/guides/introduction/): Required for authenticating and interacting with Jira

## Installation

1. Download the script:
   ```bash
   curl -o jira.sh https://raw.githubusercontent.com/username/jira-bash/main/jira.sh
   chmod +x jira.sh
   ```

2. Move to a directory in your PATH:
   ```bash
   sudo mv jira.sh /usr/local/bin/jira
   # Or locally:
   mv jira.sh ~/bin/jira  # Ensure ~/bin is in your PATH
   ```

3. First-time configuration:
   ```bash
   jira config
   ```

## Usage

### Basic Commands

```bash
# List your recent tickets
jira list

# View details of a specific ticket
jira view PROJECT-123

# Create a new ticket
jira create --summary "Fix login issue" --description "Users cannot log in from Firefox"

# Add a comment to a ticket
jira comment PROJECT-123 "This has been fixed in the latest release"

# Change a ticket's status
jira transition PROJECT-123 "Done"

# Assign a ticket
jira assign PROJECT-123 --assignee "user@example.com"
```

### Sprint Management

```bash
# List all sprints
jira sprint list

# View sprint details
jira sprint view 42

# Create a new sprint
jira sprint create "Sprint 7" --start-date 2025-06-01 --end-date 2025-06-15 --goal "Implement OAuth"

# Start a sprint
jira sprint start 42

# Add a ticket to a sprint
jira sprint add PROJECT-123 42

# Close a sprint
jira sprint close 42
```

### Epic Management

```bash
# List all epics
jira epic list

# View epic details and child issues
jira epic view PROJECT-100

# Create a new epic
jira epic create "User Authentication Overhaul"

# Add a ticket to an epic
jira epic add PROJECT-123 PROJECT-100
```

### Global Options

```
--dry-run          Show what would happen without making changes
--verbose or -v    Show detailed debugging information
--format <fmt>     Output format: default, json, or csv
```

## Configuration

The script stores configuration in `~/.config/jira-cli/`:

- `config.sh`: Contains your Jira URL, default project, and other preferences
- `credentials`: Securely stores your Jira username and API token

You can edit these files directly or run `jira config` for guided setup.

## Comparison with Alternatives

- **jira-bash**: Simple, single-file Bash script with excellent sprint and epic support
- **go-jira**: More developer-focused with extensive filtering capabilities
- **jira-cli**: Official Atlassian tool with cloud and server support
- **jirash**: More customizable but requires more setup

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.