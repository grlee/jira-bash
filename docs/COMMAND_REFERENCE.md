# Jira-Bash Command Reference

This document provides a detailed reference for all commands available in the Jira-Bash CLI tool.

## Global Options

These options can be used with any command:

| Option | Description | Example |
|--------|-------------|---------|
| `--help`, `-h` | Show help information | `jira --help` |
| `--verbose`, `-v` | Show detailed debug information | `jira list -v` |
| `--dry-run` | Show what would happen without making changes | `jira create --summary "Bug" --dry-run` |
| `--format <fmt>` | Output format (default, json, csv) | `jira list --format json` |

## Basic Commands

### Configuration

```bash
jira config
```

Interactively configures your Jira settings, including URL, project, and authentication details.

### Listing Tickets

```bash
jira list [options]
```

Options:
- `--project`, `-p <proj>`: Specify project (default from config)
- `--limit`, `-l <num>`: Limit number of results (default: 10)
- `--query`, `-q <jql>`: Custom JQL query

Examples:
```bash
# List 10 most recent tickets in your default project
jira list

# List 20 tickets from the PROJ project
jira list --project PROJ --limit 20

# List all tickets with status "In Progress"
jira list --query "status = 'In Progress'"

# List tickets assigned to you
jira list --query "assignee = currentUser()"
```

### Viewing Tickets

```bash
jira view <ticket-id> [options]
```

Options:
- `--format <fmt>`: Output format (default, json, csv)

Examples:
```bash
# View details of ticket PROJ-123
jira view PROJ-123

# View ticket details in JSON format
jira view PROJ-123 --format json
```

### Creating Tickets

```bash
jira create [options]
```

Options:
- `--project`, `-p <proj>`: Project key (default from config)
- `--summary`, `-s <text>`: Ticket summary (required)
- `--description`, `-d <text>`: Ticket description
- `--type`, `-t <type>`: Issue type (default: Task)
- `--assignee`, `-a <email>`: Assignee email
- `--priority`, `-r <priority>`: Priority (default: Medium)
- `--parent <key>`: Parent issue key for subtasks or epic for stories

Examples:
```bash
# Create a simple task
jira create --summary "Fix login bug"

# Create a detailed bug report
jira create --summary "Users can't login with Firefox" --type Bug --description "Steps: 1. Open Firefox 2. Attempt login" --priority High

# Create a subtask
jira create --summary "Update docs" --parent PROJ-123
```

### Adding Comments

```bash
jira comment <ticket-id> [comment text] [options]
```

If comment text is not provided on the command line, your default editor will open.

Examples:
```bash
# Add a simple comment
jira comment PROJ-123 "Fixed in latest release"

# Open editor to compose a comment
jira comment PROJ-123
```

### Transitioning Tickets

```bash
jira transition <ticket-id> <status> [options]
```

Examples:
```bash
# Move a ticket to "In Progress"
jira transition PROJ-123 "In Progress"

# Mark a ticket as "Done"
jira transition PROJ-123 "Done"
```

### Assigning Tickets

```bash
jira assign <ticket-id> --assignee <email> [options]
```

Examples:
```bash
# Assign a ticket to someone
jira assign PROJ-123 --assignee "user@example.com"

# Self-assign a ticket
jira assign PROJ-123 --assignee "$(git config user.email)"
```

## Sprint Management

### Listing Sprints

```bash
jira sprint list [options]
```

Options:
- `--project`, `-p <proj>`: Project key (default from config)

Examples:
```bash
# List all sprints in your default project
jira sprint list

# List sprints for a specific project
jira sprint list --project PROJ
```

### Viewing Sprint Details

```bash
jira sprint view <sprint-id> [options]
```

Examples:
```bash
# View details of sprint 42
jira sprint view 42
```

### Creating Sprints

```bash
jira sprint create <name> [options]
```

Options:
- `--start-date <date>`: Start date (YYYY-MM-DD)
- `--end-date <date>`: End date (YYYY-MM-DD)
- `--goal <text>`: Sprint goal

Examples:
```bash
# Create a basic sprint
jira sprint create "Sprint 7"

# Create a sprint with dates and goal
jira sprint create "Sprint 7" --start-date 2025-06-01 --end-date 2025-06-15 --goal "Complete the login feature"
```

### Starting Sprints

```bash
jira sprint start <sprint-id> [options]
```

Examples:
```bash
# Start sprint 42
jira sprint start 42
```

### Adding Issues to Sprints

```bash
jira sprint add <ticket-id> <sprint-id> [options]
```

Examples:
```bash
# Add ticket PROJ-123 to sprint 42
jira sprint add PROJ-123 42
```

### Closing Sprints

```bash
jira sprint close <sprint-id> [options]
```

Examples:
```bash
# Close sprint 42
jira sprint close 42
```

## Epic Management

### Listing Epics

```bash
jira epic list [options]
```

Options:
- `--project`, `-p <proj>`: Project key (default from config)

Examples:
```bash
# List all epics in your default project
jira epic list

# List epics for a specific project
jira epic list --project PROJ
```

### Viewing Epic Details

```bash
jira epic view <epic-id> [options]
```

Examples:
```bash
# View details of epic PROJ-100
jira epic view PROJ-100
```

### Creating Epics

```bash
jira epic create <name> [options]
```

Options:
- `--description`, `-d <text>`: Epic description

Examples:
```bash
# Create a basic epic
jira epic create "User Authentication"

# Create an epic with description
jira epic create "User Authentication" --description "All tasks related to user authentication and authorization"
```

### Adding Issues to Epics

```bash
jira epic add <ticket-id> <epic-id> [options]
```

Examples:
```bash
# Add ticket PROJ-123 to epic PROJ-100
jira epic add PROJ-123 PROJ-100
```

## Environment Variables

The script respects these environment variables:

- `JIRA_URL`: Override the URL in config file
- `JIRA_PROJECT`: Override default project in config file
- `JIRA_API_VERSION`: Override API version in config file
- `JIRA_CLI_VERBOSE`: Set to "true" to enable verbose mode

Example:
```bash
JIRA_URL=https://your-instance.atlassian.net JIRA_PROJECT=NEWPROJ jira list
```