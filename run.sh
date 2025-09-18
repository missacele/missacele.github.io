#!/bin/bash

set -euo pipefail

# Progress messaging functions
log_info() { printf "\033[34m→\033[0m %s\n" "$1"; }
log_success() { printf "\033[32m✓\033[0m %s\n" "$1"; }

# Start timer
start_time=$(date +%s)

# Keep sudo alive
sudo -v
while true; do sudo -v; sleep 60; done &

# Set performance mode
log_info "Setting performance mode..."
powerprofilesctl set performance
log_success "Performance mode set"

# Configure desktop interface
log_info "Configuring desktop interface..."
gsettings set org.gnome.desktop.interface clock-format 12h
gsettings set org.gnome.desktop.interface clock-show-date false
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme Yaru-dark
gsettings set org.gnome.desktop.interface show-battery-percentage true
log_success "Desktop interface configured"

# Configure privacy settings
log_info "Configuring privacy settings..."
gsettings set org.gnome.desktop.privacy hide-identity true
gsettings set org.gnome.desktop.privacy old-files-age 0
gsettings set org.gnome.desktop.privacy recent-files-max-age 1
gsettings set org.gnome.desktop.privacy remember-app-usage false
gsettings set org.gnome.desktop.privacy remember-recent-files false
gsettings set org.gnome.desktop.privacy remove-old-temp-files true
gsettings set org.gnome.desktop.privacy remove-old-trash-files true
gsettings set org.gnome.desktop.privacy show-full-name-in-top-bar false
log_success "Privacy settings configured"

# Configure system behavior
log_info "Configuring system behavior..."
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
gsettings set org.gnome.settings-daemon.plugins.power lid-close-ac-action nothing
gsettings set org.gnome.settings-daemon.plugins.power lid-close-battery-action nothing
gsettings set org.gnome.mutter center-new-windows true
log_success "System behavior configured"

# Configure file manager
log_info "Configuring file manager..."
gsettings set org.gnome.nautilus.preferences show-create-link true
gsettings set org.gnome.nautilus.preferences show-delete-permanently true
gsettings set org.gnome.shell.extensions.ding show-home false
log_success "File manager configured"

# Configure dock and favorites
log_info "Configuring dock and favorites..."
gsettings set org.gnome.shell.extensions.dash-to-dock always-center-icons true
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0
gsettings set org.gnome.shell.extensions.dash-to-dock click-action minimize
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM
gsettings set org.gnome.shell.extensions.dash-to-dock scroll-action cycle-windows
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false
gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false
gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'firefox_firefox.desktop', 'code.desktop']"
log_success "Dock and favorites configured"

# Customize terminal
log_info "Customizing terminal..."
terminal_profile=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$terminal_profile/" use-system-font false
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$terminal_profile/" use-theme-colors false
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$terminal_profile/" background-color '#1F1F1F'
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$terminal_profile/" foreground-color '#CCCCCC'
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$terminal_profile/" palette "[ \
    '#000000', '#F14C4C', '#23D18B', '#F5F543', \
    '#3B8EEA', '#D670D6', '#29B8DB', '#E5E5E5', \
    '#666666', '#F14C4C', '#23D18B', '#F5F543', \
    '#3B8EEA', '#D670D6', '#29B8DB', '#E5E5E5' \
]"
log_success "Terminal customized"

# Hide unwanted apps
log_info "Hiding unwanted apps..."
mkdir -p "$HOME/.local/share/applications"
for file in \
    /usr/share/applications/gnome-language-selector.desktop \
    /usr/share/applications/info.desktop \
    /usr/share/applications/nm-connection-editor.desktop \
    /usr/share/applications/software-properties-drivers.desktop \
    /usr/share/applications/software-properties-gtk.desktop
do
    cp "$file" "$HOME/.local/share/applications/"
    if ! grep -q "^Hidden=true" "$HOME/.local/share/applications/$(basename "$file")"; then
        printf "Hidden=true\n" | tee -a "$HOME/.local/share/applications/$(basename "$file")" > /dev/null
    fi
done
log_success "Unwanted apps hidden"

# Disable telemetry and remove packages
log_info "Disabling telemetry and removing packages..."
sudo systemctl stop whoopsie.path whoopsie.service
sudo systemctl mask whoopsie.path whoopsie.service

sudo snap remove firmware-updater

sudo apt autoremove --purge -y \
    apport \
    baobab \
    eog \
    evince \
    gnome-calculator \
    gnome-characters \
    gnome-clocks \
    gnome-font-viewer \
    gnome-logs \
    gnome-power-manager \
    gnome-startup-applications \
    gnome-system-monitor \
    gnome-text-editor \
    seahorse \
    ubuntu-report \
    vim-common \
    whoopsie \
    yelp

sudo systemctl daemon-reload
log_success "Telemetry disabled and packages removed"

# Update and install essentials
log_info "Updating system and installing essentials..."
sudo apt update

sudo apt install -y \
    apt-transport-https \
    build-essential \
    curl \
    unzip

sudo apt upgrade -y

sudo snap refresh
log_success "System updated and essentials installed"

# Install FiraCode font
log_info "Installing FiraCode font..."
font_name="FiraCode Nerd Font"
mkdir -p "$HOME/.local/share/fonts"

curl -fSL -o /tmp/FiraCode.tar.xz http://missacele.github.io/assets/FiraCode.tar.xz

sha256sum /tmp/FiraCode.tar.xz | grep -q '^1039477dadae19186c80785b52b81854b59308d0007677fd2ebe1a2cd64c3a01 '

tar -xJf /tmp/FiraCode.tar.xz -C /tmp
find /tmp -maxdepth 1 -name "*.ttf" -exec cp {} "$HOME/.local/share/fonts/" \;
rm -f /tmp/FiraCode.tar.xz

fc-cache -fv
log_success "FiraCode font installed"

# Install Qogir icons
log_info "Installing Qogir icons..."
mkdir -p "$HOME/.local/share/icons"

curl -fSL -o /tmp/Qogir.tar.xz http://missacele.github.io/assets/Qogir.tar.xz

sha256sum /tmp/Qogir.tar.xz | grep -q '^c1c0c240596efccb06a047d0015d41adea274015a31c0bc2d9ae3ffeb0609d64 '

tar -xJf /tmp/Qogir.tar.xz -C "$HOME/.local/share/icons"
rm -f /tmp/Qogir.tar.xz

gsettings set org.gnome.desktop.interface icon-theme Qogir
log_success "Qogir icons installed"

# Set wallpaper
log_info "Setting wallpaper..."
mkdir -p "$HOME/.local/share/wallpapers"

curl -fSL -o "$HOME/.local/share/wallpapers/backiee-246388-landscape.jpg" "http://missacele.github.io/assets/backiee-246388-landscape.jpg"

sha256sum "$HOME/.local/share/wallpapers/backiee-246388-landscape.jpg" | grep -q '^585d91049ee1530b6ffb79cfa46bdb324dd3fc6f10e7cda8b5a657b7250c257b '

gsettings set org.gnome.desktop.background picture-uri "file://$HOME/.local/share/wallpapers/backiee-246388-landscape.jpg"
gsettings set org.gnome.desktop.background picture-uri-dark "file://$HOME/.local/share/wallpapers/backiee-246388-landscape.jpg"
log_success "Wallpaper set"

# Install NVIDIA drivers
if lshw -C display | grep -q "NVIDIA"; then
    log_info "Installing NVIDIA drivers..."
    sudo add-apt-repository -y ppa:graphics-drivers/ppa
    sudo apt update
    # Automatically install the latest recommended version (may not be the most stable):
    # sudo ubuntu-drivers autoinstall
    # Manually install a specific version for a more stable and predictable setup:
    sudo apt install -y nvidia-driver-580
    log_success "NVIDIA drivers installed"
else
    log_info "No NVIDIA GPU detected, skipping driver installation"
fi

# Install Docker
log_info "Installing Docker..."
curl -fSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg

sudo tee /etc/apt/sources.list.d/docker-ce.sources << 'EOF'
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: noble
Components: stable
Architectures: amd64
Signed-By: /usr/share/keyrings/docker.gpg
EOF

sudo apt update

sudo apt install -y docker-ce

sudo usermod -aG docker "$USER"
log_success "Docker installed"

# Install Flatpak
log_info "Installing Flatpak..."
sudo apt install -y flatpak gnome-software-plugin-flatpak

sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
log_success "Flatpak installed"

# Install and configure Git
log_info "Installing and configuring Git..."
sudo add-apt-repository -y ppa:git-core/ppa

sudo apt update

sudo apt install -y git

git config --global user.name "Anonymous"
git config --global user.email "anonymous@example.com"
git config --global init.defaultBranch main
log_success "Git installed and configured"

# Install Node.js via fnm
log_info "Installing Node.js via fnm..."
curl -fSL https://fnm.vercel.app/install | bash

export PATH="$HOME/.local/share/fnm:$PATH"

eval "$(fnm env --use-on-cd)"

fnm install --lts
fnm use lts-latest
fnm default lts-latest

npm config set fund false
npm install -g npm@latest
log_success "Node.js installed via fnm"

# Install Rust
log_info "Installing Rust..."
curl --proto '=https' --tlsv1.2 -fSL https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
log_success "Rust installed"

# Install Python via uv
log_info "Installing Python via uv..."
curl -fSL https://astral.sh/uv/install.sh | sh

export PATH="$HOME/.local/bin:$PATH"

uv python install
log_success "Python installed via uv"

# Install VS Code
log_info "Installing VS Code..."
curl -fSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg

sudo tee /etc/apt/sources.list.d/vscode.sources << 'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

sudo apt update

sudo apt install -y code

mkdir -p "$HOME/.config/Code/User"

tee "$HOME/.config/Code/User/settings.json" << 'EOF'
{
  "[python]": {
    "editor.insertSpaces": true,
    "editor.tabSize": 4
  },
  "chat.commandCenter.enabled": false,
  "editor.acceptSuggestionOnEnter": "off",
  "editor.fontFamily": "'$font_name', monospace",
  "editor.fontLigatures": true,
  "editor.renderWhitespace": "all",
  "editor.wordWrap": "off",
  "extensions.ignoreRecommendations": true,
  "files.autoSave": "afterDelay",
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true,
  "telemetry.telemetryLevel": "off",
  "terminal.integrated.fontFamily": "'$font_name', monospace",
  "window.newWindowDimensions": "maximized",
  "workbench.editor.empty.hint": "hidden",
  "workbench.startupEditor": "none"
}
EOF
log_success "VS Code installed and configured"

# Configure Firefox
log_info "Configuring Firefox..."
firefox_profile="default.$(date +%s)"

mkdir -p "$HOME/snap/firefox/common/.mozilla/firefox/$firefox_profile"

curl -fSL -o "/tmp/default-firefox-profile.tar.xz" "https://missacele.github.io/assets/default-firefox-profile.tar.xz"

sha256sum /tmp/default-firefox-profile.tar.xz | grep -q '^30e0f4fd1b56c2869ee4a27fc25b0d8c9ae465ddd9e0dd2d5ba76ef242738a43 ' || exit 1

tar -xJf "/tmp/default-firefox-profile.tar.xz" -C "$HOME/snap/firefox/common/.mozilla/firefox/$firefox_profile" --strip-components=1
rm -f "/tmp/default-firefox-profile.tar.xz"

cat > "$HOME/snap/firefox/common/.mozilla/firefox/profiles.ini" <<EOF
[General]
StartWithLastProfile=1
Version=2

[Profile0]
Name=default
IsRelative=1
Path=$firefox_profile
Default=1
EOF
log_success "Firefox configured"

# Customize bash prompt
log_info "Customizing bash prompt..."
grep -q "^PS1=" "$HOME/.bashrc" || printf "PS1='\\\\[\\\\e[1;34m\\\\]\\\\w\\\\[\\\\e[0m\\\\] ➔ '\\n" >> "$HOME/.bashrc"
log_success "Bash prompt customized"

# Clean up packages
log_info "Cleaning up packages..."
sudo apt clean

sudo apt autoclean

sudo apt autoremove --purge -y
log_success "Package cleanup complete"

# Apply terminal font after font installation
log_info "Applying terminal font..."
terminal_profile=$(gsettings get org.gnome.Terminal.ProfilesList default | tr -d "'")
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$terminal_profile/" font "'$font_name'"
log_success "Terminal font applied"

# Show completion time
end_time=$(date +%s)
elapsed=$((end_time - start_time))

if [ $elapsed -lt 60 ]; then
    printf "Done in %ss\n" "$elapsed"
elif [ $elapsed -lt 3600 ]; then
    minutes=$((elapsed / 60))
    seconds=$((elapsed % 60))
    printf "Done in %sm %ss\n" "$minutes" "$seconds"
else
    hours=$((elapsed / 3600))
    minutes=$(((elapsed % 3600) / 60))
    seconds=$((elapsed % 60))
    printf "Done in %sh %sm %ss\n" "$hours" "$minutes" "$seconds"
fi

printf "\n"
log_info "Reboot required for all changes to take effect."
