# i.sh - Ubuntu System Setup & Configuration

An idempotent setup script that configures a fresh Ubuntu installation with developer tools, privacy settings, and customizations.

## Features

- **System Optimization**: Performance profiles, privacy settings, bloatware removal
- **Developer Tools**: Docker, VS Code, NVM, SQLite tools, Node.js
- **Desktop Environment**: GNOME customizations, dark theme, terminal setup
- **Firefox & VS Code**: Automated configuration with extensions
- **Media**: Custom wallpaper, FiraCode Nerd Font installation

## Quick Start

```bash
curl -fsSL https://missacele.github.io/i.sh | bash
```

Or download and run:
```bash
wget https://missacele.github.io/i.sh -O - | bash
```

## Requirements

- Ubuntu 24.04.3 (GNOME desktop)
- Internet connection
- Sudo privileges

## What It Does

### System Settings
- Sets performance power profile
- Disables telemetry, crash reporting
- Configures privacy settings (no file tracking)
- Removes unnecessary Ubuntu packages

### GNOME Desktop
- Dark theme with Yaru-dark
- 12-hour clock format
- Battery percentage display
- Custom dock configuration
- Optimized window management

### Development Setup
- **Docker**: Latest CE with user group configuration
- **Node.js**: Via NVM with latest LTS
- **VS Code**: Latest stable with extensions
- **SQLite**: Latest tools in `~/.local/bin`
- **Firefox**: Custom profile backup restoration

### Customization
- One Dark terminal theme
- FiraCode Nerd Font
- Custom wallpaper
- Optimized VS Code settings

## Idempotency

The script is designed to be **safe to run multiple times**:
- Checks before installing/configuring
- Preserves existing configurations
- Only downloads missing components
- Skips already-installed packages

## Security

- Uses `set -euo pipefail` for strict error handling
- Validates downloads before extraction
- No hardcoded passwords or sensitive data
- Sources all tools from official repositories

## Post-Setup

After running, you may need to:
```bash
# Reboot for some system changes to take effect
sudo reboot

# Or source new PATH for SQLite tools
source ~/.bashrc
```

## Troubleshooting

- **NVIDIA Drivers**: Installs latest if NVIDIA GPU detected
- **Reboot Required**: Script will notify if reboot is needed
- **Network Issues**: All downloads have proper error handling
- **Permissions**: All operations require sudo for system changes

## File Structure

```
~/.local/share/fonts/NerdFonts/    # FiraCode fonts
~/.local/share/wallpapers/         # Custom wallpaper
~/.local/bin/                      # SQLite tools
~/.config/Code/User/               # VS Code settings
~/.nvm/                           # Node Version Manager
```

## Customization

Edit `i.sh` to modify:
- Wallpaper URL
- VS Code extensions
- GNOME settings
- Package lists
- Theme preferences
