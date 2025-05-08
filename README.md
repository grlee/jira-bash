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
   # System-wide installation (requires sudo):
   sudo mv jira.sh /usr/local/bin/jira
   
   # Or user-specific installation:
   mkdir -p ~/.local/bin  # Create directory if it doesn't exist
   mv jira.sh ~/.local/bin/jira
   chmod +x ~/.local/bin/jira
   
   # Make sure the directory is in your PATH:
   # Add this to your ~/.bashrc or ~/.zshrc if needed:
   # export PATH="$PATH:$HOME/.local/bin"
   ```

3. Initialize your project:
   ```bash
   cd /path/to/your/project
   jira init
   ```

Alternatively, use the installer script:
```bash
./install.sh
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

Jira-Bash uses per-project configuration, which allows each project to connect to its own specific Jira instance.

### Project Configuration

Each project has its own configuration file in the project's root directory:

- `.jira-config.ini`: Contains project-specific settings including:
  - Jira URL for this project
  - Project key
  - Default options like issue type and priority

### Credentials

Credentials are stored centrally to avoid duplicating sensitive information:

- `~/.config/jira-cli/credentials`: Securely stores your Jira username and API token

### Setting Up a New Project

To initialize a new project with jira-bash:

```bash
cd /path/to/your/project
jira init
```

This creates a `.jira-config.ini` file in your project directory that you'll need to edit to set your specific Jira URL.

## Documentation

For more detailed documentation, see:

- [Command Reference](docs/COMMAND_REFERENCE.md) - Detailed usage for all commands
- [Platform Compatibility](docs/PLATFORM_COMPATIBILITY.md) - Notes for different operating systems
- [Alternatives Comparison](docs/ALTERNATIVES.md) - How jira-bash compares to other tools
- [Project Status](docs/PROJECT_STATUS.md) - Current status and roadmap

## Contributing

Contributions are welcome! Please check out our [Contributing Guide](CONTRIBUTING.md) for more information.

## Testing

Run the included test script to verify functionality:

```bash
./test.sh
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.