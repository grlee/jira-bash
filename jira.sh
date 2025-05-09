#!/bin/bash
#
# jira.sh - Advanced wrapper script for JIRA operations with sprint and epic management
# Simplifies common JIRA operations for any project
#
# Author: George
# Version: 1.0.0
#
# MIT License
#
# Copyright (c) 2025 George Lee
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

set -e

# Script constants
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME=$(basename "$0")

#
# Utility functions
#

# Check if a command exists in the PATH
function command_exists() {
    command -v "$1" &> /dev/null
}

# Display error message and exit
function die() {
    local message="$1"
    local exit_code="${2:-1}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Color codes for error messages
    local RED='\033[0;31m'
    local NC='\033[0m' # No Color
    
    # Format error message
    echo -e "${RED}[ERROR]${NC} ${timestamp}: $message" >&2
    
    # Add extra context if available
    if [ -n "$3" ]; then
        echo -e "  Context: $3" >&2
    fi
    
    # Show hint for help if appropriate
    if [ "$exit_code" -eq 1 ] && [ "$COMMAND" != "help" ] && [ "$COMMAND" != "config" ]; then
        echo -e "  Hint: Run '$SCRIPT_NAME --help' for usage information" >&2
    fi
    
    # Only exit if not in test mode
    if [[ "${TEST_MODE:-false}" != "true" ]]; then
        exit "$exit_code"
    else
        return "$exit_code"
    fi
}

# Display verbose messages if verbose mode is enabled
function verbose() {
    if $VERBOSE; then
        echo "[VERBOSE] $1"
    fi
}

# Check for required dependencies
function check_dependencies() {
    if ! command_exists acli; then
        die "The 'acli' command was not found. 
The Atlassian CLI tool (acli) is required for this script to function.

Please install acli and ensure it's available in your PATH:
- For installation and usage, refer to: https://developer.atlassian.com/cloud/acli/guides/introduction/
- Ensure authentication is configured for your Jira instance" 1
    fi
}

# Initialize script by checking dependencies
check_dependencies

#
# Configuration management
#

# Configuration paths
readonly CONFIG_DIR="${HOME}/.config/jira-cli"
readonly PROJECT_CONFIG_FILE=".jira-config.ini"
readonly CREDENTIALS_FILE="${CONFIG_DIR}/credentials"

# Default settings
DEFAULT_LIMIT=10
DEFAULT_TYPE="Task"
DEFAULT_PRIORITY="Medium"
DEFAULT_JIRA_API_VERSION="3"
DRY_RUN=false
VERBOSE=false
OUTPUT_FORMAT="default"
# JIRA_URL and PROJECT must be set in project config

# Create a project configuration file
function create_project_config() {
    # Get the current directory name as default project key
    local current_dir=$(basename "$(pwd)")
    local project_key=${current_dir^^} # Convert to uppercase for JIRA project key
    local jira_url="$1"  # Get the URL passed from init_project
    
    cat > "${PROJECT_CONFIG_FILE}" << EOL
; jira-cli project configuration file
; This file configures jira-cli for the current project

[jira]
; REQUIRED: Jira URL (without trailing slash)
url=${jira_url}

; REQUIRED: Project key
project=${project_key}

; Jira API version
api_version=${DEFAULT_JIRA_API_VERSION}

[defaults]
; Default limit for listing tickets
limit=${DEFAULT_LIMIT}

; Default issue type
type=${DEFAULT_TYPE}

; Default priority
priority=${DEFAULT_PRIORITY}
EOL
    chmod 600 "${PROJECT_CONFIG_FILE}"  # Secure file with credentials
    
    echo "Created project configuration file at $(pwd)/${PROJECT_CONFIG_FILE}"
    if [ -z "$jira_url" ]; then
        echo "IMPORTANT: You MUST set the url value in the [jira] section"
    else
        echo "Jira URL set to: $jira_url"
    fi
}

# Initialize Jira configuration
function initialize_jira_config() {
    local config_updated=false
    
    # Prompt for Jira URL update
    if prompt_for_config_update "JIRA_URL" "${JIRA_URL}" \
        "Your Jira URL is currently set to" \
        "Enter your Jira URL (without trailing slash, e.g., https://your-domain.atlassian.net)" \
        "${DEFAULT_JIRA_URL}"; then
        config_updated=true
    fi
    
    # Prompt for project update
    if prompt_for_config_update "DEFAULT_PROJECT" "${DEFAULT_PROJECT}" \
        "Your default project is currently set to" \
        "Enter your default Jira project key (e.g., PROJECT)" \
        "KAN"; then
        config_updated=true
    fi
    
    if $config_updated; then
        echo "Configuration updated successfully!"
    fi
}

# Initialize project with Jira settings
function init_project() {
    # Ask for Jira URL before creating config
    local jira_url=""
    local valid_url=false
    
    while [ "$valid_url" = false ]; do
        echo "Enter your Jira URL (without trailing slash, e.g., https://your-domain.atlassian.net):"
        read -r jira_url
        
        # Basic URL validation
        if [[ "$jira_url" =~ ^https?://[a-zA-Z0-9.-]+\.[a-zA-Z][a-zA-Z]+$ ]]; then
            # Remove trailing slash if present
            jira_url=${jira_url%/}
            valid_url=true
        else
            echo "Invalid URL format. Please enter a valid URL (e.g., https://your-domain.atlassian.net)"
        fi
    done
    
    # Create project configuration file with the provided URL
    create_project_config "$jira_url"
    
    # Check credentials
    if [ ! -f "${CREDENTIALS_FILE}" ] || [ ! -s "${CREDENTIALS_FILE}" ]; then
        echo "Jira credentials are not configured."
        echo "Would you like to configure them now? (y/n)"
        read -r setup_creds
        
        if [[ "$setup_creds" == "y" || "$setup_creds" == "Y" ]]; then
            setup_credentials
        fi
    else
        echo "Jira credentials are already configured."
        echo "Would you like to update them? (y/n)"
        read -r update_creds
        
        if [[ "$update_creds" == "y" || "$update_creds" == "Y" ]]; then
            setup_credentials
        fi
    fi
    
    echo "Project initialization complete."
    echo "Configuration saved to ${PROJECT_CONFIG_FILE}"
}

# Function is no longer needed - project initialization is now a separate command

# Check for default settings and warn user
function check_default_settings() {
    if [[ -z "${JIRA_URL}" && "$1" != "-h" && "$1" != "--help" && "$1" != "init" ]]; then
        echo "Error: JIRA_URL is not set in your project configuration."
        echo "Please edit $(pwd)/${PROJECT_CONFIG_FILE} to set your Jira URL."
        exit 1
    fi
}

# Function to check if we're in a project with JIRA config
function find_project_config() {
    if [ -f "${PROJECT_CONFIG_FILE}" ]; then
        verbose "Found project config file in current directory"
        return 0
    fi
    
    verbose "No project config file found in current directory"
    return 1
}

# Function to read a value from INI file
function read_ini() {
    local file="$1"
    local section="$2"
    local key="$3"
    local default_val="${4:-}"
    
    # Use grep to find the section and key
    local val=$(grep -A 20 "^\[${section}\]" "$file" | grep -m 1 "^${key}=" | cut -d'=' -f2-)
    
    # Return the value, or default if not found
    if [ -n "$val" ]; then
        echo "$val"
    else
        echo "$default_val"
    fi
}

# Load configuration
function load_config() {
    # Create credentials directory if it doesn't exist
    mkdir -p "${CONFIG_DIR}" 2>/dev/null || true
    
    # Try to load project-specific configuration
    if find_project_config; then
        verbose "Loading project configuration from ${PROJECT_CONFIG_FILE}"
        
        # Read configuration values from INI file
        JIRA_URL=$(read_ini "${PROJECT_CONFIG_FILE}" "jira" "url")
        PROJECT=$(read_ini "${PROJECT_CONFIG_FILE}" "jira" "project")
        JIRA_API_VERSION=$(read_ini "${PROJECT_CONFIG_FILE}" "jira" "api_version" "${DEFAULT_JIRA_API_VERSION}")
        DEFAULT_LIMIT=$(read_ini "${PROJECT_CONFIG_FILE}" "defaults" "limit" "${DEFAULT_LIMIT}")
        DEFAULT_TYPE=$(read_ini "${PROJECT_CONFIG_FILE}" "defaults" "type" "${DEFAULT_TYPE}")
        DEFAULT_PRIORITY=$(read_ini "${PROJECT_CONFIG_FILE}" "defaults" "priority" "${DEFAULT_PRIORITY}")
    else
        if [[ "$1" != "init" && "$1" != "-h" && "$1" != "--help" ]]; then
            echo "Error: No project configuration found in the current directory."
            echo "You need to initialize a project configuration first."
            echo "Run '${SCRIPT_NAME} init' to create a project configuration file."
            exit 1
        fi
    fi
}

# Initialize configuration
load_config "$@"

# Function for verbose logging
verbose() {
    if $VERBOSE; then
        echo "[VERBOSE] $1"
    fi
}

#
# Help and documentation functions
#

# Show help information
function show_help() {
    echo "$SCRIPT_NAME - JIRA ticket manager"
    echo "Version: $SCRIPT_VERSION"
    echo ""
    echo "Usage:"
    echo "  $SCRIPT_NAME [command] [options]"
    echo ""
    echo "Commands:"
    echo "  init                   Initialize a project with Jira configuration"
    echo "  list                   List tickets (default command)"
    echo "  view <ticket-id>       View details of a specific ticket"
    echo "  create                 Create a new ticket"
    echo "  comment <ticket-id>    Add a comment to a ticket"
    echo "  transition <ticket-id> Change ticket status"
    echo "  assign <ticket-id>     Assign a ticket to someone"
    echo "  sprint <subcommand>    Manage sprints (list|view|create|start|add|close)"
    echo "  epic <subcommand>      Manage epics (list|view|create|add)"
    echo ""
    echo "Options:"
    echo "  -h, --help             Show this help message"
    echo "  -p, --project <proj>   Specify project (default: $DEFAULT_PROJECT)"
    echo "  -l, --limit <num>      Limit number of results (default: $DEFAULT_LIMIT)"
    echo "  -q, --query <jql>      Custom JQL query"
    echo "  -s, --summary <text>   Ticket summary"
    echo "  -d, --description <d>  Ticket description"
    echo "  -t, --type <type>      Ticket type (default: $DEFAULT_TYPE)"
    echo "  -a, --assignee <email> Assignee email"
    echo "  -r, --priority <prio>  Priority (default: $DEFAULT_PRIORITY) - Currently informational only"
    echo "  --status <status>      Status for transition"
    echo "  --parent <key>         Parent issue key for subtasks or epic for stories"
    echo "  --start-date <date>    Start date (YYYY-MM-DD) for sprints/versions"
    echo "  --end-date <date>      End date (YYYY-MM-DD) for sprints/versions"
    echo "  --goal <text>          Sprint goal"
    echo "  --dry-run              Show what would happen without making changes"
    echo "  -v, --verbose          Show detailed debugging information"
    echo "  --format <fmt>         Output format: default, json, csv (default: $OUTPUT_FORMAT)"
    echo ""
    echo "Authentication:"
    echo "  The script automatically logs in to acli using credentials stored in:"
    echo "  $CREDENTIALS_FILE"
    echo "  Run '$SCRIPT_NAME config' to set up or update your credentials."
    echo ""
    
    show_examples
}

# Show command examples
function show_examples() {
    echo "Sprint Command Examples:"
    echo "  $SCRIPT_NAME sprint list               # List all sprints"
    echo "  $SCRIPT_NAME sprint view 1             # View sprint details"
    echo "  $SCRIPT_NAME sprint create \"Sprint 3\" --start-date 2025-06-01 --end-date 2025-06-15 --goal \"Complete feature X\""
    echo "  $SCRIPT_NAME sprint start 3            # Start sprint 3"
    echo "  $SCRIPT_NAME sprint add KAN-42 3       # Add ticket to sprint 3"
    echo "  $SCRIPT_NAME sprint close 3            # Close sprint 3"
    echo ""
    echo "Epic Command Examples:"
    echo "  $SCRIPT_NAME epic list                 # List all epics"
    echo "  $SCRIPT_NAME epic view KAN-100         # View epic details"
    echo "  $SCRIPT_NAME epic create \"User Auth\"   # Create a new epic"
    echo "  $SCRIPT_NAME epic add KAN-42 KAN-100   # Add ticket to epic"
    echo ""
    echo "Basic Command Examples:"
    echo "  $SCRIPT_NAME init                        # Initialize project Jira configuration"
    echo "  $SCRIPT_NAME list                        # List 10 most recent tickets"
    echo "  $SCRIPT_NAME list --limit 20             # List 20 tickets"
    echo "  $SCRIPT_NAME list --query \"status = Done\" # List tickets with status Done"
    echo "  $SCRIPT_NAME view KAN-42                 # View details of KAN-42"
    echo "  $SCRIPT_NAME create --summary \"Fix bug\"  # Create a new task"
    echo "  $SCRIPT_NAME comment KAN-42 \"Fixed bug\"  # Add comment to KAN-42"
    echo "  $SCRIPT_NAME transition KAN-42 \"Done\"    # Mark KAN-42 as Done"
    echo "  $SCRIPT_NAME assign KAN-42 user@mail.com # Assign KAN-42"
    echo "  $SCRIPT_NAME create --summary \"Fix bug\" --dry-run # Show what would happen"
    echo "  $SCRIPT_NAME list --format json          # Output in JSON format"
    echo "  $SCRIPT_NAME list --verbose              # Show login and API details"
    echo ""
    echo "Configuration:"
    echo "  Project configuration is stored in: .jira-config.sh in each project directory"
    echo "  Credentials are stored securely in ${CREDENTIALS_FILE}"
    echo ""
}

#
# Argument parsing functions
#

# Process positional arguments for tickets and commands
function process_positional_args() {
    # Set defaults
    COMMAND="list"
    TICKET_ID=""
    COMMENT=""
    STATUS=""
    SPRINT_COMMAND=""
    EPIC_COMMAND=""
    SPRINT_NAME=""
    SPRINT_ID=""
    EPIC_ID=""
    PARENT_KEY=""
    START_DATE=""
    END_DATE=""
    GOAL=""
    
    verbose "Original arguments: $*"
    
    # Process first argument as command if it doesn't start with "-"
    if [ $# -gt 0 ] && [[ ! "$1" == -* ]]; then
        COMMAND="$1"
        verbose "Command set to: $COMMAND"
        shift
    fi
    
    # Process second argument based on command
    case "$COMMAND" in
        view|comment|transition|assign)
            if [ $# -gt 0 ] && [[ ! "$1" == -* ]]; then
                TICKET_ID="$1"
                verbose "Ticket ID set to: $TICKET_ID"
                shift
            fi
            ;;
        sprint)
            if [ $# -gt 0 ] && [[ ! "$1" == -* ]]; then
                SPRINT_COMMAND="$1"
                shift
    
                # Process sprint command arguments
                case "$SPRINT_COMMAND" in
                    view|start|close)
                        if [ $# -gt 0 ] && [[ ! "$1" == -* ]]; then
                            SPRINT_ID="$1"
                            shift
                        fi
                        ;;
                    create)
                        if [ $# -gt 0 ] && [[ ! "$1" == -* ]]; then
                            SPRINT_NAME="$1"
                            shift
                        fi
                        ;;
                    add)
                        if [ $# -gt 0 ] && [[ ! "$1" == -* ]]; then
                            TICKET_ID="$1"
                            shift
                            if [ $# -gt 0 ] && [[ ! "$1" == -* ]]; then
                                SPRINT_ID="$1"
                                shift
                            fi
                        fi
                        ;;
                esac
            fi
            ;;
        epic)
            if [ $# -gt 0 ] && [[ ! "$1" == -* ]]; then
                EPIC_COMMAND="$1"
                shift
    
                # Process epic command arguments
                case "$EPIC_COMMAND" in
                    view)
                        if [ $# -gt 0 ] && [[ ! "$1" == -* ]]; then
                            EPIC_ID="$1"
                            shift
                        fi
                        ;;
                    create)
                        if [ $# -gt 0 ] && [[ ! "$1" == -* ]]; then
                            SPRINT_NAME="$1" # Reusing SPRINT_NAME variable for epic name
                            shift
                        fi
                        ;;
                    add)
                        if [ $# -gt 0 ] && [[ ! "$1" == -* ]]; then
                            TICKET_ID="$1"
                            shift
                            if [ $# -gt 0 ] && [[ ! "$1" == -* ]]; then
                                EPIC_ID="$1"
                                shift
                            fi
                        fi
                        ;;
                esac
            fi
            ;;
    esac
    
    # Process third argument as comment text or transition status
    if [ $# -gt 0 ] && [[ ! "$1" == -* ]] && [[ "$COMMAND" == "comment" ]]; then
        COMMENT="$1"
        shift
    elif [ $# -gt 0 ] && [[ ! "$1" == -* ]] && [[ "$COMMAND" == "transition" ]]; then
        STATUS="$1"
        shift
    fi
    
    
    # Return remaining arguments for option parsing
    echo "$@"
}

# Parse command line options (flags)
function parse_options() {
    # Don't overwrite if already set by process_positional_args
    # Set default values only if they're not already set
    PROJECT="${PROJECT:-$DEFAULT_PROJECT}"
    LIMIT="${LIMIT:-$DEFAULT_LIMIT}"
    QUERY="${QUERY:-}"
    SUMMARY="${SUMMARY:-}"
    DESCRIPTION="${DESCRIPTION:-}"
    TYPE="${TYPE:-$DEFAULT_TYPE}"
    ASSIGNEE="${ASSIGNEE:-}"
    PRIORITY="${PRIORITY:-$DEFAULT_PRIORITY}"
    
    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -p|--project)
                PROJECT="$2"
                shift 2
                ;;
            -l|--limit)
                LIMIT="$2"
                shift 2
                ;;
            -q|--query)
                QUERY="$2"
                shift 2
                ;;
            -s|--summary)
                SUMMARY="$2"
                shift 2
                ;;
            -d|--description)
                DESCRIPTION="$2"
                shift 2
                ;;
            -t|--type)
                TYPE="$2"
                shift 2
                ;;
            -a|--assignee)
                ASSIGNEE="$2"
                shift 2
                ;;
            -r|--priority)
                PRIORITY="$2"
                shift 2
                ;;
            --status)
                STATUS="$2"
                shift 2
                ;;
            --parent)
                PARENT_KEY="$2"
                shift 2
                ;;
            --start-date)
                START_DATE="$2"
                shift 2
                ;;
            --end-date)
                END_DATE="$2"
                shift 2
                ;;
            --goal)
                GOAL="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            --format)
                OUTPUT_FORMAT="$2"
                shift 2
                ;;
            *)
                echo "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Parse all command line arguments
function parse_args() {
    # Set default command
    COMMAND="list"
    
    # Check if the first argument is 'init' and handle it specially
    if [ "$1" = "init" ]; then
        COMMAND="init"
        return
    fi
    
    # Process positional arguments first (command name, ticket ID, etc.)
    local remaining_args
    remaining_args=$(process_positional_args "$@")
    
    # Process remaining flag arguments
    if [[ -n "$remaining_args" ]]; then
        eval set -- "$remaining_args"
        parse_options "$@"
    fi
    
    # Output debug info if verbose
    verbose "Command: $COMMAND"
    if [ -n "$TICKET_ID" ]; then
        verbose "Ticket ID: $TICKET_ID"
    fi
    verbose "Project: $PROJECT"
    verbose "Limit: $LIMIT"
    if [ -n "$QUERY" ]; then
        verbose "Query: $QUERY"
    fi
    verbose "Dry run: $DRY_RUN"
}

# Handle command-line arguments manually
if [ $# -gt 0 ]; then
    # First argument is the command
    COMMAND="$1"
    shift
    
    # For view, transition, comment, assign commands, second arg is ticket ID
    if [[ "$COMMAND" == "view" || "$COMMAND" == "transition" || "$COMMAND" == "comment" || "$COMMAND" == "assign" ]]; then
        if [ $# -gt 0 ]; then
            TICKET_ID="$1"
            shift
        fi
    fi
    
    # For sprint and epic commands, handle their subcommands
    if [[ "$COMMAND" == "sprint" || "$COMMAND" == "epic" ]]; then
        if [ $# -gt 0 ]; then
            if [ "$COMMAND" == "sprint" ]; then
                SPRINT_COMMAND="$1"
            else
                EPIC_COMMAND="$1"
            fi
            shift
        fi
    fi
    
    # For comment command, third arg is the comment text
    if [[ "$COMMAND" == "comment" && $# -gt 0 ]]; then
        COMMENT="$1"
        shift
    fi
    
    # For transition command, third arg is the status
    if [[ "$COMMAND" == "transition" && $# -gt 0 ]]; then
        STATUS="$1"
        shift
    fi
    
    # Parse any remaining args as options
    parse_options "$@"
else
    # No args, default to list command
    COMMAND="list"
    parse_options "$@"
fi

verbose "Command: $COMMAND"
if [ -n "$TICKET_ID" ]; then
    verbose "Ticket ID: $TICKET_ID"
fi

# Execute commands
verbose "Running command: $COMMAND"
verbose "Project: $PROJECT"
verbose "Limit: $LIMIT"
verbose "Query: $QUERY"
verbose "Dry run: $DRY_RUN"

#
# API and Authentication functions
#

# Get the JIRA API URL from configuration
function get_jira_api_url() {
    local url="${JIRA_URL:-${DEFAULT_JIRA_URL}}"
    local api_version="${JIRA_API_VERSION:-${DEFAULT_JIRA_API_VERSION}}"
    
    # Extract the base domain for JIRA
    local base_url=$(echo "$url" | sed -E 's/(https?:\/\/[^\/]+).*/\1/')
    
    echo "${base_url}/rest/api/${api_version}"
}

# Get the JIRA site domain (for acli)
function get_jira_site() {
    local url="${JIRA_URL:-${DEFAULT_JIRA_URL}}"
    
    # Extract just the domain part without protocol
    echo "$url" | sed -E 's|https?://([^/]+).*|\1|'
}

# Prompt for and save credentials
function setup_credentials() {
    local jira_user
    local jira_token
    
    echo "Enter your Jira email/username:"
    read -r jira_user
    
    echo "Enter your Jira API token or password:"
    read -rs jira_token
    
    # Create the credentials file
    echo "${jira_user}:${jira_token}" > "${CREDENTIALS_FILE}"
    chmod 600 "${CREDENTIALS_FILE}"
    
    echo "Credentials saved to ${CREDENTIALS_FILE}"
}

# Get authentication credentials for API calls
function get_auth_credentials() {
    # Check if credentials are stored in the config directory
    if [ ! -f "${CREDENTIALS_FILE}" ]; then
        # First check if we can get credentials from acli
        if command_exists acli; then
            verbose "Attempting to get credentials from acli configuration..."
            # Placeholder: In a real implementation, you would extract these from acli's config
        fi
        
        # If we still don't have credentials, prompt the user
        echo "Jira credentials not found."
        echo "Would you like to configure them now? (y/n)"
        read -r setup_creds
        
        if [[ "$setup_creds" == "y" || "$setup_creds" == "Y" ]]; then
            setup_credentials
        else
            echo "No credentials configured. API calls will likely fail."
            echo "You can configure credentials later by editing ${CREDENTIALS_FILE}"
            echo "Format: username:api_token"
            echo "" > "${CREDENTIALS_FILE}"
            chmod 600 "${CREDENTIALS_FILE}"
        fi
    fi
    
    # Read credentials from file
    if [ -s "${CREDENTIALS_FILE}" ]; then
        local auth_string=$(cat "${CREDENTIALS_FILE}")
        echo "Basic $(echo -n "${auth_string}" | base64)"
    else
        echo "Basic CREDENTIALS_NOT_CONFIGURED"
    fi
}

# Check if acli is already logged in
# Returns:
# 0 - Already logged in with the proper account
# 1 - Not logged in or logged in with a different account
function check_acli_login() {
    # Check if acli is installed
    if ! command_exists acli; then
        verbose "acli command not found"
        return 1
    fi
    
    # Check if credentials file exists and has content
    if [ ! -f "${CREDENTIALS_FILE}" ] || [ ! -s "${CREDENTIALS_FILE}" ]; then
        verbose "No credentials file found or empty file"
        return 1
    fi
    
    # Extract username from credentials file
    local auth_string=$(cat "${CREDENTIALS_FILE}")
    local username=$(echo "$auth_string" | cut -d':' -f1)
    
    # Use acli auth status to check the current login state
    local status_output=$(acli auth status 2>/dev/null)
    verbose "Auth status output: $status_output"
    
    # Check if the status output contains the username and a token
    if echo "$status_output" | grep -q "Authenticated" && \
       echo "$status_output" | grep -q "$username" && \
       echo "$status_output" | grep -q "Token:"; then
        verbose "Already logged in to acli as $username"
        return 0
    else
        verbose "Not logged in or logged in as different user (expected: '$username')"
        verbose "Status output: $status_output"
        return 1
    fi
}

# Login to Atlassian CLI (acli) using stored configuration
# This function ensures acli is logged in with the correct account
# before executing any Jira commands
function login_to_acli() {
    # Check if acli is installed
    if ! command_exists acli; then
        die "The 'acli' command was not found. Please install acli." 1
    fi
    
    verbose "Checking acli login status..."
    
    # Check if already logged in with the correct account
    if check_acli_login; then
        return 0
    fi
    
    # Check if credentials file exists and has content
    if [ ! -f "${CREDENTIALS_FILE}" ] || [ ! -s "${CREDENTIALS_FILE}" ]; then
        verbose "No credentials file found or empty file."
        return 1
    fi
    
    # Extract username (email) and token from credentials file
    local auth_string=$(cat "${CREDENTIALS_FILE}")
    local username=$(echo "$auth_string" | cut -d':' -f1)
    local token=$(echo "$auth_string" | cut -d':' -f2-)
    
    verbose "Logging in to acli as $username..."
    
    # Login to acli
    if $DRY_RUN; then
        echo "[DRY RUN] Would login to acli with username: $username"
        return 0
    else
        # Use the JIRA URL from our config
        local jira_url="${JIRA_URL:-${DEFAULT_JIRA_URL}}"
        
        # Execute login - this would typically use acli auth login
        # The exact method depends on acli's authentication mechanism
        echo "Logging in to Jira at $jira_url as $username"
        
        # Attempt to login with stored credentials
        # Using proper acli auth login syntax for version 1.0.4-beta
        if command_exists acli && [[ "$username" && "$token" ]]; then
            # Get the site domain using our helper function
            local site=$(get_jira_site)
            
            echo "Authenticating with acli..."
            verbose "Using site: $site, email: $username"
            
            # Use proper acli auth login command with site and email parameters
            echo "$token" | acli auth login --site "$site" --email "$username" --token 2>/dev/null
            
            # Wait a moment for login to complete
            sleep 1
            
            # Check if login was successful
            if check_acli_login; then
                echo "Successfully logged in to acli as $username"
                return 0
            else
                # Try one more time with explicit status check
                local status_output=$(acli auth status 2>/dev/null)
                if echo "$status_output" | grep -q "Authenticated" && \
                   echo "$status_output" | grep -q "$username"; then
                    echo "Successfully logged in to acli as $username"
                    return 0
                else
                    echo "Failed to login to acli. Please check your credentials."
                    verbose "Status output: $status_output"
                    return 1
                fi
            fi
        else
            echo "Missing username or token in credentials file."
            return 1
        fi
    fi
}

# Update a configuration value in the config file
function update_config_value() {
    local key="$1"
    local value="$2"
    local config_file="$3"
    
    # Make sure the config file exists
    if [ ! -f "$config_file" ]; then
        create_default_config
    fi
    
    # Update the config file with sed
    sed -i "s|$key=.*|$key=\"$value\"|" "$config_file"
    
    # Update the variable in the current shell
    eval "$key=\"$value\""
    
    verbose "Updated $key to '$value' in $config_file"
}

# Prompt user to update a config setting
function prompt_for_config_update() {
    local key="$1"            # The configuration key
    local current_value="$2"  # The current value
    local prompt_msg="$3"     # The message to display
    local input_msg="$4"      # The input prompt
    local default_value="$5"  # The default value to compare against
    
    if [ -z "$default_value" ] || [ "$current_value" == "$default_value" ]; then
        echo "$prompt_msg: $current_value"
        echo "Would you like to update it now? (y/n)"
        read -r update_val
        
        if [[ "$update_val" == "y" || "$update_val" == "Y" ]]; then
            echo "$input_msg:"
            read -r new_value
            
            update_config_value "$key" "$new_value" "$CONFIG_FILE"
            return 0
        fi
    fi
    
    return 1
}

# Make a REST API call to JIRA
function jira_api_call() {
    local method="$1"
    local endpoint="$2"
    local data="$3"

    local api_url=$(get_jira_api_url)
    local auth=$(get_auth_credentials)
    local url="${api_url}${endpoint}"

    verbose "Making API call: $method $url"
    if [ -n "$data" ]; then
        verbose "With data: $data"
    fi

    if $DRY_RUN; then
        echo "[DRY RUN] Would make API call: $method $url"
        if [ -n "$data" ]; then
            echo "[DRY RUN] With data: $data"
        fi
        echo "[DRY RUN] No actual API call made."
        return 0
    fi

    # Set up temporary file for response
    local tmp_file
    tmp_file=$(mktemp) || die "Failed to create temporary file"
    
    # Prepare curl command with proper headers
    local curl_cmd="curl -s -X $method"
    curl_cmd="$curl_cmd -H 'Authorization: $auth'"
    curl_cmd="$curl_cmd -H 'Content-Type: application/json'"
    curl_cmd="$curl_cmd -H 'Accept: application/json'"
    
    # Add data for non-GET requests
    if [ "$method" != "GET" ] && [ -n "$data" ]; then
        curl_cmd="$curl_cmd -d '$data'"
    fi
    
    # Add URL
    curl_cmd="$curl_cmd '$url'"
    
    # Execute the curl command and capture output
    verbose "Executing: $curl_cmd"
    eval "$curl_cmd > $tmp_file"
    
    local status=$?
    if [ $status -ne 0 ]; then
        rm -f "$tmp_file"
        die "API call failed with status $status" $status
    fi
    
    # Check for error response
    if grep -q "\"errorMessages\"" "$tmp_file"; then
        local error_msg
        error_msg=$(jq -r '.errorMessages[0] // "Unknown error"' "$tmp_file" 2>/dev/null)
        if [ -z "$error_msg" ] || [ "$error_msg" = "null" ]; then
            error_msg="API error without specific message"
        fi
        rm -f "$tmp_file"
        die "API error: $error_msg" 1
    fi
    
    # Output the response
    cat "$tmp_file"
    
    # Clean up
    rm -f "$tmp_file"
}

#
# Issue management functions
#

# List tickets with JQL query
function list_tickets() {
    verbose "Listing tickets with limit: $LIMIT"
    verbose "Output format: $OUTPUT_FORMAT"

    # Build the search command
    local jql_query=""
    
    if [ -n "$QUERY" ]; then
        jql_query="$QUERY"
        verbose "Using custom query: $QUERY"
    else
        jql_query="project = $PROJECT"
        verbose "Using default project query: project = $PROJECT"
    fi
    
    # Get the site from our config
    local site=$(get_jira_site)
    verbose "Using site: $site"
    
    # Check acli version to determine correct command structure
    local acli_version=$(acli --version | grep -oP '\d+\.\d+\.\d+' || echo "")
    verbose "acli version: $acli_version"
    
    # Build command based on output format
    if $DRY_RUN; then
        echo "[DRY RUN] Would fetch up to $LIMIT tickets from project $PROJECT"
        echo "[DRY RUN] JQL query: $jql_query"
    else
        echo "Fetching tickets for project $PROJECT (limit: $LIMIT)..."
        
        # Get all Jira issues matching our criteria
        if [ "$OUTPUT_FORMAT" = "json" ]; then
            acli jira workitem search --jql "$jql_query" --limit "$LIMIT" --json
        elif [ "$OUTPUT_FORMAT" = "csv" ]; then
            # For CSV we need to format the output ourselves
            acli jira workitem search --jql "$jql_query" --limit "$LIMIT" --csv
        else
            # Default output format
            acli jira workitem search --jql "$jql_query" --limit "$LIMIT"
        fi
    fi
}

# View details of a specific ticket
function view_ticket() {
    if [ -z "$TICKET_ID" ]; then
        die "Ticket ID is required"
    fi
    
    verbose "Viewing ticket: $TICKET_ID"
    verbose "Output format: $OUTPUT_FORMAT"

    # Get the site from our config
    local site=$(get_jira_site)
    verbose "Using site: $site"
    
    if $DRY_RUN; then
        echo "[DRY RUN] Would view details for ticket $TICKET_ID"
    else
        echo "Fetching details for $TICKET_ID..."
        
        if [ "$OUTPUT_FORMAT" = "json" ]; then
            acli jira workitem view "$TICKET_ID" --json
        elif [ "$OUTPUT_FORMAT" = "csv" ]; then
            # For CSV we need to format the output ourselves
            acli jira workitem view "$TICKET_ID" --csv
        else
            # Default output format
            acli jira workitem view "$TICKET_ID"
        fi
    fi
}

# Validate input for ticket creation
function validate_ticket_input() {
    # Validate project
    if [ -z "$PROJECT" ]; then
        die "Project is required" 1 "Specify with --project PROJECT"
    fi
    
    # Validate summary
    if [ -z "$SUMMARY" ]; then
        die "Summary is required" 1 "Specify with --summary \"Your summary\""
    fi
    
    # Validate ticket type against common types
    local valid_types=("Task" "Bug" "Story" "Epic" "Subtask")
    local type_valid=false
    
    for valid_type in "${valid_types[@]}"; do
        if [[ "$TYPE" == "$valid_type" ]]; then
            type_valid=true
            break
        fi
    done
    
    if ! $type_valid; then
        echo "Warning: Uncommon issue type: '$TYPE'"
        echo "Common types are: ${valid_types[*]}"
        echo "Continuing with '$TYPE' as specified..."
    fi
    
    # Validate assignee email format if specified
    if [ -n "$ASSIGNEE" ] && ! [[ "$ASSIGNEE" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        die "Invalid email format for assignee: $ASSIGNEE" 1 "Specify a valid email address"
    fi
    
    # Validate parent key format if specified
    if [ -n "$PARENT_KEY" ] && ! [[ "$PARENT_KEY" =~ ^[A-Z]+-[0-9]+$ ]]; then
        die "Invalid parent key format: $PARENT_KEY" 1 "Should be in the format PROJECT-123"
    fi
    
    return 0
}

# Create a new ticket
function create_ticket() {
    # Validate inputs
    validate_ticket_input || return $?
    
    verbose "Creating new ticket"
    verbose "Summary: $SUMMARY"
    verbose "Type: $TYPE"
    verbose "Project: $PROJECT"

    # Get the site from our config
    local site=$(get_jira_site)
    verbose "Using site: $site"
    
    if $DRY_RUN; then
        echo "[DRY RUN] Would create a new ticket in project $PROJECT"
        echo "[DRY RUN] Summary: $SUMMARY"
        echo "[DRY RUN] Type: $TYPE"
        if [ -n "$DESCRIPTION" ]; then
            echo "[DRY RUN] Description: ${DESCRIPTION:0:50}..."
        fi
        if [ -n "$ASSIGNEE" ]; then
            echo "[DRY RUN] Assignee: $ASSIGNEE"
        fi
        if [ -n "$PARENT_KEY" ]; then
            echo "[DRY RUN] Parent: $PARENT_KEY"
        fi
    else
        echo "Creating new ticket in project $PROJECT..."
        
        local create_cmd="acli jira workitem create --project $PROJECT --type \"$TYPE\" --summary \"$SUMMARY\""
        
        if [ -n "$DESCRIPTION" ]; then
            create_cmd="$create_cmd --description \"$DESCRIPTION\""
        fi
        
        if [ -n "$ASSIGNEE" ]; then
            create_cmd="$create_cmd --assignee \"$ASSIGNEE\""
        fi
        
        if [ -n "$PARENT_KEY" ]; then
            create_cmd="$create_cmd --parent \"$PARENT_KEY\""
        fi
        
        verbose "Executing: $create_cmd"
        local result
        result=$(eval "$create_cmd" 2>&1)
        local status=$?
        
        if [ $status -ne 0 ]; then
            die "Failed to create ticket" $status "$result"
        else
            echo "$result"
            # Extract the ticket key from the result if available
            local ticket_key
            ticket_key=$(echo "$result" | grep -o '[A-Z]\+-[0-9]\+' | head -1)
            if [ -n "$ticket_key" ]; then
                echo "Successfully created ticket: $ticket_key"
            else
                echo "Ticket created successfully"
            fi
        fi
    fi
}

# Add a comment to a ticket
function add_comment() {
    if [ -z "$TICKET_ID" ]; then
        die "Ticket ID is required"
    fi

    if [ -n "$COMMENT" ]; then
        if $DRY_RUN; then
            echo "[DRY RUN] Would add comment to $TICKET_ID: \"$COMMENT\""
        else
            acli jira workitem comment --key "$TICKET_ID" --body "$COMMENT"
        fi
    else
        if $DRY_RUN; then
            echo "[DRY RUN] Would open editor to add comment to $TICKET_ID"
        else
            acli jira workitem comment --key "$TICKET_ID" --editor
        fi
    fi
}

# Change the status of a ticket
function transition_ticket() {
    if [ -z "$TICKET_ID" ]; then
        die "Ticket ID is required"
    fi

    if [ -z "$STATUS" ]; then
        die "Status is required. Use: $SCRIPT_NAME transition KAN-XX \"In Progress\""
    fi

    if $DRY_RUN; then
        echo "[DRY RUN] Would transition $TICKET_ID to status: \"$STATUS\""
    else
        acli jira workitem transition --key "$TICKET_ID" --status "$STATUS"
    fi
}

# Assign a ticket to someone
function assign_ticket() {
    if [ -z "$TICKET_ID" ]; then
        die "Ticket ID is required"
    fi

    if [ -z "$ASSIGNEE" ]; then
        die "Assignee is required. Use: $SCRIPT_NAME assign KAN-XX --assignee \"email@example.com\""
    fi

    if $DRY_RUN; then
        echo "[DRY RUN] Would assign $TICKET_ID to: \"$ASSIGNEE\""
    else
        acli jira workitem assign --key "$TICKET_ID" --assignee "$ASSIGNEE"
    fi
}

#
# Sprint management functions
#

# List all sprints
function list_sprints() {
    verbose "Listing all sprints"

    # Make API call to get sprints
    if $DRY_RUN; then
        echo "[DRY RUN] Would list all sprints for project $PROJECT"
    else
        echo "Listing sprints for project $PROJECT"
        
        # First, get the board ID for the project
        verbose "Getting board ID for project $PROJECT"
        local board_id_response
        board_id_response=$(acli jira board list --project "$PROJECT" --json 2>/dev/null)
        local status=$?
        
        if [ $status -ne 0 ]; then
            die "Failed to get board ID for project $PROJECT" $status
        fi
        
        # Extract the board ID(s)
        local board_ids
        board_ids=$(echo "$board_id_response" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | head -1)
        
        if [ -z "$board_ids" ]; then
            die "No board found for project $PROJECT" 1 "Make sure the project has at least one board"
        fi
        
        verbose "Found board ID: $board_ids"
        
        # For each board, get the sprints
        for board_id in $board_ids; do
            echo "Sprints for board ID $board_id:"
            
            # Get all sprints: active, future, and closed
            local active_sprints
            active_sprints=$(acli jira sprint list --board "$board_id" --state active 2>/dev/null)
            local future_sprints
            future_sprints=$(acli jira sprint list --board "$board_id" --state future 2>/dev/null)
            local closed_sprints
            closed_sprints=$(acli jira sprint list --board "$board_id" --state closed --limit 5 2>/dev/null)
            
            # Display sprints by state
            if [ -n "$active_sprints" ]; then
                echo "Active sprints:"
                echo "$active_sprints"
                echo ""
            else
                echo "No active sprints"
                echo ""
            fi
            
            if [ -n "$future_sprints" ]; then
                echo "Future sprints:"
                echo "$future_sprints"
                echo ""
            else
                echo "No future sprints"
                echo ""
            fi
            
            if [ -n "$closed_sprints" ]; then
                echo "Recent closed sprints (last 5):"
                echo "$closed_sprints"
                echo ""
            else
                echo "No recent closed sprints"
                echo ""
            fi
        done
    fi
}

# View details of a specific sprint
function view_sprint() {
    if [ -z "$SPRINT_ID" ]; then
        die "Sprint ID is required. Use: $SCRIPT_NAME sprint view <sprint-id>"
    fi

    verbose "Viewing sprint with ID: $SPRINT_ID"

    # Make API call to get sprint details
    if $DRY_RUN; then
        echo "[DRY RUN] Would view details for sprint $SPRINT_ID"
    else
        echo "Viewing sprint $SPRINT_ID"
        jira_api_call "GET" "/sprint/$SPRINT_ID" ""

        # Also get issues in this sprint
        echo "Issues in sprint $SPRINT_ID:"
        acli jira issue list --jql "sprint = $SPRINT_ID" --limit 50
    fi
}

# Create a new sprint
function create_sprint() {
    if [ -z "$SPRINT_NAME" ]; then
        die "Sprint name is required. Use: $SCRIPT_NAME sprint create \"Sprint Name\" [--start-date YYYY-MM-DD] [--end-date YYYY-MM-DD] [--goal \"Sprint Goal\"]"
    fi

    verbose "Creating sprint: $SPRINT_NAME"
    if [ -n "$START_DATE" ]; then
        verbose "Start date: $START_DATE"
    fi
    if [ -n "$END_DATE" ]; then
        verbose "End date: $END_DATE"
    fi
    if [ -n "$GOAL" ]; then
        verbose "Goal: $GOAL"
    fi

    # Build the JSON payload for sprint creation
    local sprint_data="{\"name\":\"$SPRINT_NAME\""
    if [ -n "$START_DATE" ]; then
        sprint_data="$sprint_data,\"startDate\":\"${START_DATE}T00:00:00.000Z\""
    fi
    if [ -n "$END_DATE" ]; then
        sprint_data="$sprint_data,\"endDate\":\"${END_DATE}T23:59:59.999Z\""
    fi
    if [ -n "$GOAL" ]; then
        sprint_data="$sprint_data,\"goal\":\"$GOAL\""
    fi
    sprint_data="$sprint_data,\"originBoardId\":1}"

    # Make API call to create sprint
    if $DRY_RUN; then
        echo "[DRY RUN] Would create sprint with name: $SPRINT_NAME"
    else
        echo "Creating sprint: $SPRINT_NAME"
        jira_api_call "POST" "/sprint" "$sprint_data"
    fi
}

# Start a sprint
function start_sprint() {
    if [ -z "$SPRINT_ID" ]; then
        die "Sprint ID is required. Use: $SCRIPT_NAME sprint start <sprint-id>"
    fi

    verbose "Starting sprint with ID: $SPRINT_ID"

    # Make API call to start sprint
    if $DRY_RUN; then
        echo "[DRY RUN] Would start sprint $SPRINT_ID"
    else
        echo "Starting sprint $SPRINT_ID"
        jira_api_call "POST" "/sprint/$SPRINT_ID/start" "{}"
    fi
}

# Add a ticket to a sprint
function add_to_sprint() {
    if [ -z "$TICKET_ID" ] || [ -z "$SPRINT_ID" ]; then
        die "Both ticket ID and sprint ID are required. Use: $SCRIPT_NAME sprint add <ticket-id> <sprint-id>"
    fi

    verbose "Adding ticket $TICKET_ID to sprint $SPRINT_ID"

    # Make API call to add issue to sprint
    if $DRY_RUN; then
        echo "[DRY RUN] Would add ticket $TICKET_ID to sprint $SPRINT_ID"
    else
        echo "Adding ticket $TICKET_ID to sprint $SPRINT_ID"
        jira_api_call "POST" "/sprint/$SPRINT_ID/issue" "{\"issues\":[\"$TICKET_ID\"]}"
    fi
}

# Close a sprint
function close_sprint() {
    if [ -z "$SPRINT_ID" ]; then
        die "Sprint ID is required. Use: $SCRIPT_NAME sprint close <sprint-id>"
    fi

    verbose "Closing sprint with ID: $SPRINT_ID"

    # Make API call to close sprint
    if $DRY_RUN; then
        echo "[DRY RUN] Would close sprint $SPRINT_ID"
    else
        echo "Closing sprint $SPRINT_ID"
        jira_api_call "POST" "/sprint/$SPRINT_ID/close" "{}"
    fi
}

# Handle sprint commands
function handle_sprint_command() {
    verbose "Running sprint command: $SPRINT_COMMAND"

    case "$SPRINT_COMMAND" in
        list)   list_sprints ;;
        view)   view_sprint ;;
        create) create_sprint ;;
        start)  start_sprint ;;
        add)    add_to_sprint ;;
        close)  close_sprint ;;
        *)
            echo "Unknown sprint command: $SPRINT_COMMAND"
            show_help
            exit 1
            ;;
    esac
}

#
# Epic management functions
#

# List all epics
function list_epics() {
    verbose "Listing all epics"

    # Use acli to list all epics
    if $DRY_RUN; then
        echo "[DRY RUN] Would list all epics for project $PROJECT"
    else
        echo "Listing epics for project $PROJECT"
        acli jira workitem search --jql "project = $PROJECT AND issuetype = Epic" --limit 50
    fi
}

# View details of a specific epic
function view_epic() {
    if [ -z "$EPIC_ID" ]; then
        die "Epic ID is required. Use: $SCRIPT_NAME epic view <epic-id>"
    fi

    verbose "Viewing epic with ID: $EPIC_ID"

    # Use acli to view epic details
    if $DRY_RUN; then
        echo "[DRY RUN] Would view details for epic $EPIC_ID"
    else
        echo "Epic details:"
        acli jira workitem view "$EPIC_ID"

        # Also get issues in this epic
        echo "Issues in epic $EPIC_ID:"
        acli jira workitem search --jql "\"Epic Link\" = $EPIC_ID" --limit 50
    fi
}

# Create a new epic
function create_epic() {
    if [ -z "$SPRINT_NAME" ]; then # Reusing SPRINT_NAME for epic name
        die "Epic name is required. Use: $SCRIPT_NAME epic create \"Epic Name\" [--description \"Description\"]"
    fi

    verbose "Creating epic: $SPRINT_NAME"

    # Use acli to create an epic
    if $DRY_RUN; then
        echo "[DRY RUN] Would create epic with name: $SPRINT_NAME"
        if [ -n "$DESCRIPTION" ]; then
            echo "[DRY RUN] Description: ${DESCRIPTION:0:50}..."
        fi
    else
        echo "Creating epic: $SPRINT_NAME"
        local create_cmd="acli jira workitem create --project \"$PROJECT\" --type \"Epic\" --summary \"$SPRINT_NAME\""
        
        if [ -n "$DESCRIPTION" ]; then
            create_cmd="$create_cmd --description \"$DESCRIPTION\""
        fi
        
        eval "$create_cmd"
    fi
}

# Add a ticket to an epic
function add_to_epic() {
    if [ -z "$TICKET_ID" ] || [ -z "$EPIC_ID" ]; then
        die "Both ticket ID and epic ID are required. Use: $SCRIPT_NAME epic add <ticket-id> <epic-id>"
    fi

    verbose "Adding ticket $TICKET_ID to epic $EPIC_ID"

    # Make API call to add issue to epic
    if $DRY_RUN; then
        echo "[DRY RUN] Would add ticket $TICKET_ID to epic $EPIC_ID"
    else
        echo "Adding ticket $TICKET_ID to epic $EPIC_ID"
        jira_api_call "PUT" "/issue/$TICKET_ID" "{\"fields\":{\"customfield_10014\":\"$EPIC_ID\"}}"

        # Note: In reality, you'd need to find the correct customfield
        # ID for the "Epic Link" field in your JIRA instance
    fi
}

# Handle epic commands
function handle_epic_command() {
    verbose "Running epic command: $EPIC_COMMAND"

    case "$EPIC_COMMAND" in
        list)   list_epics ;;
        view)   view_epic ;;
        create) create_epic ;;
        add)    add_to_epic ;;
        *)
            echo "Unknown epic command: $EPIC_COMMAND"
            show_help
            exit 1
            ;;
    esac
}

#
# Main command dispatcher
#

# Process the main command
function process_command() {
    # Debug command and arguments
    verbose "Processing command: $COMMAND"
    if [ -n "$TICKET_ID" ]; then
        verbose "With ticket ID: $TICKET_ID"
    fi
    
    # Handle init command separately since it doesn't need a config file
    if [[ "$COMMAND" == "init" ]]; then
        init_project
        return
    fi
    
    # Skip login for commands that don't need Jira API access
    if [[ "$COMMAND" != "help" && "$COMMAND" != "-h" && "$COMMAND" != "--help" ]]; then
        # Login to acli before executing commands
        login_to_acli || {
            echo "Failed to authenticate with Jira. Please check your credentials."
            if ! $DRY_RUN; then
                exit 1
            else
                echo "[DRY RUN] Continuing despite login failure."
            fi
        }
    fi
    
    case "$COMMAND" in
        list)        list_tickets ;;
        view)        
            if [ -z "$TICKET_ID" ]; then
                die "Ticket ID is required for view command. Use: $SCRIPT_NAME view <ticket-id>"
            fi
            view_ticket 
            ;;
        create)      create_ticket ;;
        comment)     
            if [ -z "$TICKET_ID" ]; then
                die "Ticket ID is required for comment command. Use: $SCRIPT_NAME comment <ticket-id> [comment text]"
            fi
            add_comment 
            ;;
        transition)  
            if [ -z "$TICKET_ID" ]; then
                die "Ticket ID is required for transition command. Use: $SCRIPT_NAME transition <ticket-id> [status]"
            fi
            transition_ticket 
            ;;
        assign)      
            if [ -z "$TICKET_ID" ]; then
                die "Ticket ID is required for assign command. Use: $SCRIPT_NAME assign <ticket-id> --assignee <email>"
            fi
            assign_ticket 
            ;;
        sprint)      handle_sprint_command ;;
        epic)        handle_epic_command ;;
        *)
            echo "Unknown command: $COMMAND"
            show_help
            exit 1
            ;;
    esac
}


# Execute the command
process_command