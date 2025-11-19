#!/bin/bash
# Main setup script for Linux
# This script orchestrates the setup of a new Linux machine by running modular scripts

set -e

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMON_DIR="$ROOT_DIR/common"
SCRIPTS_DIR="$ROOT_DIR/scripts"

# Source common utilities
source "$COMMON_DIR/lib.sh"

# Check if running on Linux
if ! is_linux; then
    log_error "This script is for Linux only. Use mac/setup_mac.sh for macOS."
    exit 1
fi

# Function to run a script if it exists
run_script() {
    local script="$1"
    local description="$2"
    
    if [ ! -f "$script" ]; then
        log_warning "Script not found: $script"
        return 1
    fi
    
    log_info "=========================================="
    log_info "$description"
    log_info "=========================================="
    
    if [ -x "$script" ]; then
        "$script" || {
            log_error "Failed to run: $script"
            return 1
        }
    else
        chmod +x "$script"
        "$script" || {
            log_error "Failed to run: $script"
            return 1
        }
    fi
    
    echo ""
}

# Main setup function
main() {
    echo "=========================================="
    echo "  Linux Setup Script"
    echo "=========================================="
    echo ""
    log_info "Detected Linux"
    
    # Detect package manager
    local pm=$(command -v apt-get &> /dev/null && echo "apt" || \
               command -v yum &> /dev/null && echo "yum" || \
               command -v dnf &> /dev/null && echo "dnf" || \
               command -v pacman &> /dev/null && echo "pacman" || \
               command -v zypper &> /dev/null && echo "zypper" || \
               echo "unknown")
    log_info "Detected package manager: $pm"
    echo ""
    
    # Step 1: Install essential tools
    if prompt_yes_no "Install essential command-line tools?" "y"; then
        run_script "$SCRIPTS_DIR/install_essential_tools.sh" "Installing Essential Tools"
    fi
    
    # Step 2: Set up shell
    if prompt_yes_no "Set up zsh and Oh My Zsh?" "y"; then
        run_script "$SCRIPTS_DIR/setup_shell.sh" "Setting Up Shell"
    fi
    
    # Step 3: Set up yadm
    if prompt_yes_no "Set up yadm for dotfiles management?" "y"; then
        run_script "$SCRIPTS_DIR/setup_yadm.sh" "Setting Up yadm"
        
        # Optionally run dotfiles listing
        if [ -f "$SCRIPTS_DIR/list_dotfiles.py" ]; then
            if prompt_yes_no "List and analyze dotfiles?" "n"; then
                log_info "Running dotfiles analysis..."
                python3 "$SCRIPTS_DIR/list_dotfiles.py"
                echo ""
            fi
        fi
    fi
    
    # Step 4: Set up Python
    if prompt_yes_no "Set up Python development environment?" "y"; then
        run_script "$SCRIPTS_DIR/setup_python.sh" "Setting Up Python"
    fi
    
    # Step 5: Set up Node.js
    if prompt_yes_no "Set up Node.js?" "y"; then
        run_script "$SCRIPTS_DIR/setup_nodejs.sh" "Setting Up Node.js"
    fi
    
    # Step 6: Set up conda/mamba and install packages from config
    if prompt_yes_no "Set up conda/mamba and install packages from config?" "n"; then
        run_script "$SCRIPTS_DIR/setup_conda.sh" "Setting Up Conda/Mamba"
    fi
    
    echo "=========================================="
    log_success "Linux setup complete!"
    echo "=========================================="
    echo ""
    echo "Next steps:"
    echo "  1. Restart your terminal to apply shell changes"
    echo "  2. Run 'yadm add ~/.zshrc' to add your dotfiles (if using yadm)"
    echo "  3. Run 'yadm commit -m \"Initial commit\"' (if using yadm)"
    echo "  4. Customize your dotfiles as needed"
    echo ""
}

# Run main function
main "$@"

