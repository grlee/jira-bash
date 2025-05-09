#!/bin/bash
#
# install.sh - Installer for jira-bash
# This script installs the jira-bash script to your system
#

set -e

# Script constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="jira.sh"
INSTALL_NAME="jira-bash"

# Welcome message
echo "======================================="
echo "  jira-bash installer"
echo "======================================="
echo

# Check for dependencies
echo "Checking dependencies..."
if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl is required but not installed. Please install curl and try again."
    exit 1
fi

if ! command -v acli >/dev/null 2>&1; then
    echo "Warning: acli (Atlassian CLI) is not installed."
    echo "This script requires acli to function properly."
    echo "Please install acli from: https://developer.atlassian.com/cloud/acli/guides/introduction/"
    
    read -p "Continue anyway? (y/n) " continue_without_acli
    if [[ ! "$continue_without_acli" =~ ^[Yy]$ ]]; then
        echo "Installation aborted."
        exit 1
    fi
fi

# Determine OS-specific install paths
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    DEFAULT_INSTALL_DIR="/usr/local/bin"
    OS_NAME="macOS"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    DEFAULT_INSTALL_DIR="/usr/local/bin"
    OS_NAME="Linux"
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
    # Windows with Git Bash or Cygwin
    DEFAULT_INSTALL_DIR="$HOME/bin"
    OS_NAME="Windows"
    
    # Create bin directory if it doesn't exist
    mkdir -p "$DEFAULT_INSTALL_DIR"
else
    # Unknown OS
    DEFAULT_INSTALL_DIR="$HOME/bin"
    OS_NAME="Unknown"
    
    # Create bin directory if it doesn't exist
    mkdir -p "$DEFAULT_INSTALL_DIR"
fi

# Get user input for install location
echo
echo "Detected operating system: $OS_NAME"
echo "Default installation directory: $DEFAULT_INSTALL_DIR"
echo
echo "Installation options:"
echo "  1) Global installation ($DEFAULT_INSTALL_DIR) - requires sudo on most systems"
echo "  2) Local installation (~/.local/bin) - user-specific installation"
echo "  3) Custom directory"
echo
read -p "Select installation option [2]: " INSTALL_OPTION
INSTALL_OPTION="${INSTALL_OPTION:-2}"

case "$INSTALL_OPTION" in
    1)
        INSTALL_DIR="$DEFAULT_INSTALL_DIR"
        ;;
    2)
        INSTALL_DIR="$HOME/.local/bin"
        # Create .local/bin if it doesn't exist
        mkdir -p "$INSTALL_DIR"
        ;;
    3)
        read -p "Enter custom install directory: " CUSTOM_DIR
        INSTALL_DIR="${CUSTOM_DIR:-$DEFAULT_INSTALL_DIR}"
        ;;
    *)
        echo "Invalid option. Using default local installation directory."
        INSTALL_DIR="$HOME/.local/bin"
        mkdir -p "$INSTALL_DIR"
        ;;
esac

# Create install directory if it doesn't exist
if [ ! -d "$INSTALL_DIR" ]; then
    echo "Creating directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR" || { echo "Error: Failed to create directory $INSTALL_DIR"; exit 1; }
fi

# Check if install directory is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "Warning: $INSTALL_DIR is not in your PATH."
    
    # Different message based on installation option
    if [[ "$INSTALL_DIR" == "$HOME/.local/bin" ]]; then
        echo "For local installation (~/.local/bin), add the following line to your ~/.bashrc, ~/.zshrc or equivalent:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
    else
        echo "Add the following line to your ~/.bashrc, ~/.zshrc or equivalent:"
        echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
    fi
fi

# Install the script
echo "Installing jira-bash to $INSTALL_DIR/$INSTALL_NAME..."

# Check if we need sudo for global installation
if [[ "$INSTALL_OPTION" == "1" && "$INSTALL_DIR" == "/usr/local/bin" && ! -w "$INSTALL_DIR" ]]; then
    echo "Global installation requires sudo privileges."
    sudo cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_DIR/$INSTALL_NAME" || { echo "Error: Failed to copy script"; exit 1; }
    sudo chmod +x "$INSTALL_DIR/$INSTALL_NAME" || { echo "Error: Failed to make script executable"; exit 1; }
else
    cp "$SCRIPT_DIR/$SCRIPT_NAME" "$INSTALL_DIR/$INSTALL_NAME" || { echo "Error: Failed to copy script"; exit 1; }
    chmod +x "$INSTALL_DIR/$INSTALL_NAME" || { echo "Error: Failed to make script executable"; exit 1; }
fi

echo
echo "Installation successful!"
echo "You can now run the jira-bash command from the terminal."
echo "To use with a project, navigate to your project directory and run:"
echo "  jira-bash init"
echo "This will create a project-specific configuration file."