# Computer Setup Scripts

This repository contains scripts and tools for setting up and managing computer configurations. These are separate from dotfiles managed by yadm.

## Contents

- **bootstrap.sh** - Comprehensive bootstrap script for setting up a new machine (Homebrew, tools, dev environments)
- **setup_yadm.sh** - Interactive script to help set up yadm for dotfiles management
- **list_dotfiles.py** - Python script to analyze and categorize dotfiles in your home directory
- **test_local.sh** - Local validation script for testing scripts before committing
- **.github/workflows/test.yml** - GitHub Actions workflow for CI/CD testing

## Usage

### Bootstrap a New Machine

```bash
./bootstrap.sh
```

### Analyze Dotfiles

```bash
python3 list_dotfiles.py
```

### Test Scripts Locally

```bash
./test_local.sh
```

## Note

This repository is separate from your yadm-managed dotfiles. The yadm repository only contains actual dotfiles (`.zshrc`, `.gitconfig`, etc.) and yadm-specific configuration (`.yadm/bootstrap`).
