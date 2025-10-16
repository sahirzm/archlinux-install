# Ubuntu Package Tracking Setup

This directory contains the Ubuntu equivalent of the Arch Linux package tracking system. It automatically tracks packages installed via APT, Cargo, and NPM.

## File Structure

```
ubuntu/
├── etc/
│   └── apt/
│       └── apt.conf.d/
│           └── 99-track-packages          # APT hook for automatic tracking
├── home/
│   └── .local/
│       └── bin/
│           ├── cargo-wrapper.sh           # Cargo wrapper for tracking
│           └── npm-wrapper.sh             # NPM wrapper for tracking
├── restore-packages.sh                    # Script to restore packages
└── README.md                              # This file
```

## Package List Files

The following files are created in the root of the repository:

- `ubuntu-pkglist.txt` - Manually installed APT packages
- `cargo-pkglist.txt` - Globally installed Cargo packages
- `npm-pkglist.txt` - Globally installed NPM packages

## Initial Setup on Ubuntu

### 1. Deploy configs with GNU Stow

```bash
cd ~/workspace/archlinux-install/ubuntu

# Install APT hook (requires sudo)
sudo stow -t / etc

# Install wrapper scripts
stow -t ~ home
```

### 2. Add shell aliases

Add these lines to your `~/.bashrc` or `~/.zshrc`:

```bash
alias cargo='~/.local/bin/cargo-wrapper.sh'
alias npm='~/.local/bin/npm-wrapper.sh'
```

Then reload your shell:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

### 3. Generate initial package lists

```bash
# APT packages
apt-mark showmanual | sort > ~/workspace/archlinux-install/ubuntu-pkglist.txt

# Cargo packages (if cargo is installed)
cargo install --list | grep -E '^[a-zA-Z0-9_-]+ v[0-9]' | awk '{print $1}' | sort > ~/workspace/archlinux-install/cargo-pkglist.txt

# NPM packages (if npm is installed, requires jq)
npm list -g --depth=0 --json 2>/dev/null | jq -r '.dependencies | keys[]' | grep -v '^npm$' | sort > ~/workspace/archlinux-install/npm-pkglist.txt
```

## Restoring Packages on a Fresh System

### 1. Clone the repository and deploy with Stow

```bash
cd ~/workspace
git clone <your-repo-url> archlinux-install
cd archlinux-install/ubuntu

# Deploy configs
sudo stow -t / etc
stow -t ~ home
```

### 2. Run the restoration script

```bash
cd ~/workspace/archlinux-install/ubuntu
chmod +x restore-packages.sh
./restore-packages.sh
```

The script will prompt you to install packages from each category (APT, Cargo, NPM).

### 3. Set up shell aliases

Follow step 2 from "Initial Setup" above to add the aliases to your shell config.

## How It Works

### APT Tracking
- The APT hook at `/etc/apt/apt.conf.d/99-track-packages` runs after every package install/remove operation
- It executes `apt-mark showmanual` to list only manually installed packages (not dependencies)
- The list is automatically saved to `ubuntu-pkglist.txt`

### Cargo Tracking
- The wrapper script intercepts `cargo install` and `cargo uninstall` commands
- After the operation completes, it runs `cargo install --list` to get all installed packages
- The list is saved to `cargo-pkglist.txt`

### NPM Tracking
- The wrapper script intercepts global NPM install/uninstall commands (with `-g` flag)
- After the operation completes, it runs `npm list -g --depth=0` to get all global packages
- The list is saved to `npm-pkglist.txt`
- **Note:** Requires `jq` to be installed for JSON parsing

## Dependencies

- **For APT tracking:** No additional dependencies (built-in)
- **For Cargo tracking:** Rust/Cargo installed
- **For NPM tracking:** Node.js/NPM and `jq` installed

## Notes

- The wrapper scripts use `command` builtin to avoid recursive calls
- Empty package list files will be created if the respective package manager is not installed
- The APT hook only tracks manually installed packages, not automatic dependencies
- Cargo and NPM wrappers only track globally installed packages, not project-local ones

## Troubleshooting

### APT hook not working
- Verify the hook is installed: `ls -l /etc/apt/apt.conf.d/99-track-packages`
- Check file permissions: should be readable (644)
- Ensure the workspace directory path is correct in the hook file

### Cargo/NPM wrapper not working
- Verify aliases are set: `alias cargo` and `alias npm`
- Ensure wrapper scripts are executable: `chmod +x ~/.local/bin/*-wrapper.sh`
- Check if the workspace directory exists and is writable

### NPM tracking not working
- Install jq: `sudo apt install jq`
- Verify npm is installed: `npm --version`
