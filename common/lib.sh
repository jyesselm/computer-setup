#!/bin/bash
# Common utility functions and variables for setup scripts
# This file should be sourced by other scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running on macOS
is_macos() {
    [[ "$OSTYPE" == "darwin"* ]]
}

# Check if running on Linux
is_linux() {
    [[ "$OSTYPE" == "linux-gnu"* ]]
}

# Get the directory where this script is located
get_script_dir() {
    local SOURCE="${BASH_SOURCE[0]}"
    while [ -h "$SOURCE" ]; do
        local DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
        SOURCE="$(readlink "$SOURCE")"
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
    done
    echo "$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
}

# Source a script if it exists
source_if_exists() {
    if [ -f "$1" ]; then
        source "$1"
        return 0
    else
        log_warning "Script not found: $1"
        return 1
    fi
}

# Prompt user for yes/no input
prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local reply
    
    if [ "$default" = "y" ]; then
        read -p "$prompt (Y/n): " -n 1 -r reply
        echo
        [[ ! $REPLY =~ ^[Nn]$ ]]
    else
        read -p "$prompt (y/N): " -n 1 -r reply
        echo
        [[ $REPLY =~ ^[Yy]$ ]]
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

