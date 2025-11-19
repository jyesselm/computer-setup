# Computer Setup Scripts

Modular setup scripts for configuring new macOS and Linux machines. These scripts are designed to be reusable and can be run individually or as part of a complete setup.

## Structure

```
computer-setup/
├── common/
│   └── lib.sh              # Shared utilities (logging, OS detection, etc.)
├── config/
│   └── conda.yml            # Configuration file for conda/mamba packages
│   └── homebrew.yml        # Configuration file for Homebrew packages (macOS)
├── mac/
│   └── setup_mac.sh        # Main entry point for macOS
├── linux/
│   └── setup_linux.sh      # Main entry point for Linux
└── scripts/
    ├── install_package_manager.sh      # Install Homebrew (Mac) or detect Linux PM
    ├── install_essential_tools.sh      # Install CLI tools (git, vim, tmux, etc.)
    ├── install_gui_apps.sh            # Install GUI apps via Homebrew Casks (Mac only)
    ├── install_homebrew_packages.sh    # Install Homebrew packages from config (Mac only)
    ├── setup_shell.sh                  # Set up zsh and Oh My Zsh
    ├── setup_yadm.sh                   # Set up yadm for dotfiles management
    ├── setup_python.sh                 # Set up Python development environment
    ├── setup_nodejs.sh                 # Set up Node.js and npm
    ├── setup_conda.sh                  # Set up conda/mamba/minimamba and install from config
    └── list_dotfiles.py                # Analyze and categorize dotfiles
```

## Quick Start

### macOS

Run the main setup script:

```bash
./mac/setup_mac.sh
```

Or run individual scripts:

```bash
./scripts/install_package_manager.sh
./scripts/install_essential_tools.sh
./scripts/setup_shell.sh
```

### Linux

Run the main setup script:

```bash
./linux/setup_linux.sh
```

Or run individual scripts:

```bash
./scripts/install_essential_tools.sh
./scripts/setup_shell.sh
```

## Individual Scripts

All scripts in the `scripts/` directory can be run independently:

- **install_package_manager.sh** - Installs Homebrew on macOS or detects Linux package manager
- **install_essential_tools.sh** - Installs essential CLI tools (git, yadm, zsh, vim, tmux, etc.). On macOS, optionally uses `config/homebrew.yml`
- **install_gui_apps.sh** - Installs GUI applications via Homebrew Casks (macOS only). Optionally uses `config/homebrew.yml`
- **install_homebrew_packages.sh** - Installs Homebrew packages and casks from `config/homebrew.yml` (macOS only)
- **setup_shell.sh** - Sets up zsh as default shell and installs Oh My Zsh
- **setup_yadm.sh** - Sets up yadm and clones dotfiles from https://github.com/jyesselm/dotfiles
- **setup_python.sh** - Sets up Python development environment with common packages
- **setup_nodejs.sh** - Installs Node.js and global npm packages
- **setup_conda.sh** - Sets up conda/mamba/minimamba and installs packages from `config/conda.yml`
- **list_dotfiles.py** - Analyzes and categorizes dotfiles in your home directory

## Features

- **Modular Design**: Each script handles a specific aspect of setup
- **Cross-Platform**: Shared scripts work on both macOS and Linux
- **Interactive**: Prompts for user confirmation before making changes
- **Reusable**: Can run individual scripts or the full setup
- **Safe**: Checks for existing installations before installing

## Requirements

- Bash 4.0+
- Python 3.6+ (for list_dotfiles.py)
- sudo access (for installing packages on Linux)

## Usage Examples

### Run full setup on macOS

```bash
chmod +x mac/setup_mac.sh
./mac/setup_mac.sh
```

### Run full setup on Linux

```bash
chmod +x linux/setup_linux.sh
./linux/setup_linux.sh
```

### Just install essential tools

```bash
chmod +x scripts/install_essential_tools.sh
./scripts/install_essential_tools.sh
```

### Set up yadm and clone dotfiles

```bash
./scripts/setup_yadm.sh
```

This will:
1. Check if yadm is installed, or install it if needed
2. Clone your dotfiles from https://github.com/jyesselm/dotfiles
3. Automatically run the bootstrap script (if present in the repository)

You can customize the repository URL by editing `scripts/setup_yadm.sh` and changing the `DOTFILES_REPO` variable.

### Analyze dotfiles

```bash
python3 scripts/list_dotfiles.py
```

### Install Homebrew packages from config (macOS)

```bash
./scripts/install_homebrew_packages.sh
```

This will:
1. Check if Homebrew is installed
2. Read packages, casks, and taps from `config/homebrew.yml`
3. Install all specified Homebrew packages and casks

You can customize the packages by editing `config/homebrew.yml`. The `install_essential_tools.sh` and `install_gui_apps.sh` scripts will also automatically use this config file if it exists.

### Set up conda/mamba and install packages from config

```bash
./scripts/setup_conda.sh
```

This will:
1. Detect if conda/mamba/minimamba is installed, or install mambaforge if not
2. Read packages from `config/conda.yml`
3. Install all specified conda and pip packages

You can customize the packages by editing `config/conda.yml`.

## Configuration Files

### Homebrew Configuration (`config/homebrew.yml`)

The `config/homebrew.yml` file allows you to define Homebrew packages and casks to install (macOS only):

```yaml
taps:
  - homebrew/cask-fonts

packages:
  - git
  - zsh
  - vim
  - node

casks:
  - iterm2
  - visual-studio-code
  - google-chrome
```

Edit this file to customize which packages are installed. The `install_essential_tools.sh` and `install_gui_apps.sh` scripts will automatically detect and use this config file if it exists.

### Conda/Mamba Configuration (`config/conda.yml`)

The `config/conda.yml` file allows you to define packages to install via conda/mamba/minimamba:

```yaml
channels:
  - conda-forge
  - defaults

conda_packages:
  - python=3.11
  - numpy
  - pandas
  - jupyter

pip_packages:
  - pip
  - poetry

environment_name: null  # Set to create a named environment
```

Edit this file to customize which packages are installed. The script will automatically detect and use conda, mamba, or minimamba (in that order of preference).

## Customization

You can customize the scripts by:

1. Editing the package lists in each script
2. Editing `config/homebrew.yml` to customize Homebrew packages (macOS)
3. Editing `config/conda.yml` to customize conda/mamba packages
4. Adding new scripts to the `scripts/` directory
5. Modifying the main setup scripts to include/exclude steps
6. Creating OS-specific variants in `mac/` or `linux/` directories

## Testing

This repository includes GitHub Actions workflows to test the setup scripts in phases:

- **macOS Testing**: Tests all setup phases on macOS (5 phases)
- **Linux Testing**: Tests all setup phases on Ubuntu (5 phases)
- **Config Validation**: Validates YAML configuration files
- **Script Linting**: Lints shell scripts with shellcheck

The workflow runs on push, pull requests, and can be manually triggered. Each phase is tested independently to catch issues early.

## Notes

- Scripts use `set -e` to exit on errors
- All scripts source `common/lib.sh` for shared utilities
- Scripts check for existing installations before installing
- Interactive prompts allow you to skip steps you don't need
- Conda environment defaults to "py3" (configurable in `config/conda.yml`)

