#!/bin/bash
set -euxo pipefail
ST=$(date +%s)
li() { printf "\033[34m→\033[0m %s\n" "$1"; }
lc() { printf "\033[32m✓\033[0m %s\n" "$1"; }
gs() { local c; c=$(gsettings get "$1" "$2" 2>&-||printf unset); [[ "$c" != "$3" ]] && gsettings set "$1" "$2" "$3" 2>&-||:; }
pm() { ! dpkg -l "$1" 2>&- | grep -q "^ii"; }
cm() { ! type "$1" >/dev/null 2>&1; }
dl() { local u="$1" o="$2" cs="$3"; [[ -f "$o" ]] && printf "%s %s\n" "$cs" "$o" | sha256sum -c --quiet 2>&- && return 0; curl -fSL -o "$o" "$u" --retry 3 --retry-delay 2 --connect-timeout 30 --max-time 300 2>&-||return 1; }
rp() { local p="$1"; dpkg -l "$p" 2>&- | grep -q "^ii" && sudo apt autoremove --purge -y "$p" 2>&-||:; }
mkd() { [[ ! -d "$1" ]] && mkdir -p "$1" 2>&-||:; }
svc() { systemctl is-active --quiet "$1" 2>&-; }
type powerprofilesctl >/dev/null && powerprofilesctl set performance 2>&-||:
gs "org.gnome.desktop.interface" "clock-format" "'12h'"
gs "org.gnome.desktop.interface" "clock-show-date" "false"
gs "org.gnome.desktop.interface" "color-scheme" "'prefer-dark'"
gs "org.gnome.desktop.interface" "gtk-theme" "'Yaru-dark'"
gs "org.gnome.desktop.interface" "show-battery-percentage" "true"
gs "org.gnome.desktop.privacy" "hide-identity" "true"
gs "org.gnome.desktop.privacy" "old-files-age" "uint32 0"
gs "org.gnome.desktop.privacy" "recent-files-max-age" "1"
gs "org.gnome.desktop.privacy" "remember-app-usage" "false"
gs "org.gnome.desktop.privacy" "remember-recent-files" "false"
gs "org.gnome.desktop.privacy" "remove-old-temp-files" "true"
gs "org.gnome.desktop.privacy" "remove-old-trash-files" "true"
gs "org.gnome.desktop.privacy" "show-full-name-in-top-bar" "false"
gs "org.gnome.desktop.session" "idle-delay" "uint32 0"
gs "org.gnome.desktop.sound" "allow-volume-above-100-percent" "true"
gs "org.gnome.desktop.wm.preferences" "button-layout" "'appmenu:minimize,maximize,close'"
gs "org.gnome.settings-daemon.plugins.power" "idle-dim" "false"
gs "org.gnome.settings-daemon.plugins.power" "lid-close-ac-action" "'nothing'"
gs "org.gnome.settings-daemon.plugins.power" "lid-close-battery-action" "'nothing'"
gs "org.gnome.mutter" "center-new-windows" "true"
gs "org.gnome.nautilus.preferences" "show-create-link" "true"
gs "org.gnome.nautilus.preferences" "show-delete-permanently" "true"
gs "org.gnome.shell.extensions.ding" "show-home" "false"
gs "org.gnome.shell.extensions.dash-to-dock" "always-center-icons" "true"
gs "org.gnome.shell.extensions.dash-to-dock" "background-opacity" "0.0"
gs "org.gnome.shell.extensions.dash-to-dock" "click-action" "'minimize'"
gs "org.gnome.shell.extensions.dash-to-dock" "dash-max-icon-size" "32"
gs "org.gnome.shell.extensions.dash-to-dock" "dock-position" "'BOTTOM'"
gs "org.gnome.shell.extensions.dash-to-dock" "scroll-action" "'cycle-windows'"
gs "org.gnome.shell.extensions.dash-to-dock" "show-apps-at-top" "true"
gs "org.gnome.shell.extensions.dash-to-dock" "show-mounts" "false"
gs "org.gnome.shell.extensions.dash-to-dock" "show-trash" "false"
gs "org.gnome.shell.extensions.dash-to-dock" "dock-fixed" "true"
gs "org.gnome.shell.extensions.dash-to-dock" "autohide" "false"
gs "org.gnome.shell.extensions.dash-to-dock" "intellihide" "false"
gs "org.gnome.shell" "favorite-apps" "['org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'firefox_firefox.desktop', 'code.desktop']"
TP=$(gsettings get org.gnome.Terminal.ProfilesList default 2>&- | tr -d "'"||printf "b1dcc9dd-5262-4d8d-a863-c897e6d979b9"); readonly TP
FN="FiraCode Nerd Font"
gs "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$TP/" "use-theme-colors" "false"
gs "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$TP/" "background-color" "'#1F1F1F'"
gs "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$TP/" "foreground-color" "'#CCCCCC'"
gs "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$TP/" "palette" "['#000000', '#F14C4C', '#23D18B', '#F5F543', '#3B8EEA', '#D670D6', '#29B8DB', '#E5E5E5', '#666666', '#F14C4C', '#23D18B', '#F5F543', '#3B8EEA', '#D670D6', '#29B8DB', '#E5E5E5']"
mkd "$HOME/.local/share/applications"
li "Hiding unwanted apps and cleaning system..."
for f in /usr/share/applications/{gnome-language-selector,info,nm-connection-editor,software-properties-drivers,software-properties-gtk}.desktop; do [[ -f "$f" ]] && { [[ ! -f "$HOME/.local/share/applications/$(basename "$f")" ]] && cp "$f" "$HOME/.local/share/applications/" 2>&-; grep -q "^Hidden=true" "$HOME/.local/share/applications/$(basename "$f")" 2>&- || printf "Hidden=true\n" >> "$HOME/.local/share/applications/$(basename "$f")" 2>&-; }; done
svc whoopsie.service && { sudo systemctl stop whoopsie.path whoopsie.service 2>&-||:; sudo systemctl mask whoopsie.path whoopsie.service 2>&-||:; }
type snap >/dev/null && snap list firmware-updater >/dev/null 2>&1 && sudo snap remove firmware-updater 2>&-||:
PKGS=(apport baobab eog evince gnome-calculator gnome-characters gnome-clocks gnome-font-viewer gnome-logs gnome-power-manager gnome-startup-applications gnome-system-monitor gnome-text-editor seahorse ubuntu-report vim-common whoopsie yelp)
INST_PKGS=()
for p in "${PKGS[@]}"; do dpkg -l "$p" 2>&- | grep -q "^ii" && INST_PKGS+=("$p"); done
[[ ${#INST_PKGS[@]} -gt 0 ]] && sudo apt autoremove --purge -y "${INST_PKGS[@]}" >/dev/null 2>&1
sudo systemctl daemon-reload 2>&-
lc "System cleaned and apps hidden"
mkd "$HOME/.local/share/wallpapers"
mkd "$HOME/.local/share/icons"
mkd "$HOME/.local/share/fonts"
mkd "/tmp"
if [[ ! -f "$HOME/snap/firefox/common/.mozilla/firefox/profiles.ini" ]]; then
    FP="default.$(date +%s)"
else
    FP=$(grep "^Path=" "$HOME/snap/firefox/common/.mozilla/firefox/profiles.ini" 2>&- | head -1 | cut -d'=' -f2)
    [[ -z "$FP" ]] && FP="default.$(date +%s)"
fi
mkd "$HOME/snap/firefox/common/.mozilla/firefox/$FP"
wait
{ pm "build-essential" && { sudo apt update -qq 2>&-||:; sudo apt install -y build-essential curl unzip &>/dev/null||:; }; } &
(dl "./assets/Qogir.tar.xz" "/tmp/Qogir.tar.xz" "c1c0c240596efccb06a047d0015d41adea274015a31c0bc2d9ae3ffeb0609d64") &
(dl "./assets/backiee-246388-landscape.jpg" "$HOME/.local/share/wallpapers/backiee-246388-landscape.jpg" "585d91049ee1530b6ffb79cfa46bdb324dd3fc6f10e7cda8b5a657b7250c257b") &
(dl "./assets/default-firefox-profile.tar.xz" "/tmp/default-firefox-profile.tar.xz" "30e0f4fd1b56c2869ee4a27fc25b0d8c9ae465ddd9e0dd2d5ba76ef242738a43") &
li "Starting downloads and updates..."
(dl "./assets/FiraCode.tar.xz" "/tmp/FiraCode.tar.xz" "1039477dadae19186c80785b52b81854b59308d0007677fd2ebe1a2cd64c3a01") &
{ sudo apt upgrade -y &>/dev/null||:; } &
{ type snap >/dev/null && sudo snap refresh &>/dev/null||:; } &
wait
lc "Downloads and updates complete"
li "Installing assets..."
{ [[ -f "/tmp/Qogir.tar.xz" ]] && [[ ! -d "$HOME/.local/share/icons/Qogir" ]] && { tar -xJf "/tmp/Qogir.tar.xz" -C "$HOME/.local/share/icons" 2>&-||:; rm -f "/tmp/Qogir.tar.xz" 2>&-||:; }; } &
{ [[ -f "/tmp/FiraCode.tar.xz" ]] && [[ ! -f "$HOME/.local/share/fonts/FiraCodeNerdFont-Regular.ttf" ]] && { tar -xJf "/tmp/FiraCode.tar.xz" -C "/tmp" 2>&-||:; find /tmp -maxdepth 1 -name "*.ttf" -exec cp {} "$HOME/.local/share/fonts/" \; 2>&-||:; rm -f "/tmp/FiraCode.tar.xz" 2>&-||:; type fc-cache >/dev/null && fc-cache -fv &>/dev/null||:; }; } &
wait
gs "org.gnome.desktop.interface" "icon-theme" "'Qogir'"
[[ -f "$HOME/.local/share/wallpapers/backiee-246388-landscape.jpg" ]] && { gs "org.gnome.desktop.background" "picture-uri" "'file://$HOME/.local/share/wallpapers/backiee-246388-landscape.jpg'"; gs "org.gnome.desktop.background" "picture-uri-dark" "'file://$HOME/.local/share/wallpapers/backiee-246388-landscape.jpg'"; }
lc "Assets installed"
[[ ! -f /usr/share/keyrings/docker.gpg ]] && { curl -fSL https://download.docker.com/linux/ubuntu/gpg --retry 3 --connect-timeout 10 | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg 2>&-||:; }
[[ ! -f /etc/apt/sources.list.d/docker-ce.sources ]] && sudo tee /etc/apt/sources.list.d/docker-ce.sources >/dev/null <<'EOF'
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: noble
Components: stable
Architectures: amd64
Signed-By: /usr/share/keyrings/docker.gpg
EOF
li "Installing development tools..."
{ pm "docker-ce" && { sudo apt update -qq &>/dev/null||:; sudo apt install -y docker-ce &>/dev/null||:; sudo usermod -aG docker "$USER" 2>&-||:; }; } &
{ pm "flatpak" && sudo apt install -y flatpak gnome-software-plugin-flatpak &>/dev/null||:; } &
{ type flatpak >/dev/null && ! flatpak remotes 2>&- | grep -q flathub && sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo &>/dev/null||:; } &
{ [[ ! -f /etc/apt/sources.list.d/git-core-ubuntu-ppa-noble.sources ]] && { sudo add-apt-repository -y ppa:git-core/ppa &>/dev/null||:; sudo apt update -qq &>/dev/null||:; }; pm "git" && sudo apt install -y git &>/dev/null||:; } &
[[ "$(git config --global user.name 2>&-)" != "Anonymous" ]] && git config --global user.name "Anonymous" 2>&-||:
[[ "$(git config --global user.email 2>&-)" != "anonymous@example.com" ]] && git config --global user.email "anonymous@example.com" 2>&-||:
[[ "$(git config --global init.defaultBranch 2>&-)" != "main" ]] && git config --global init.defaultBranch main 2>&-||:
cm "fnm" && { curl -fSL https://fnm.vercel.app/install --retry 3 --connect-timeout 10 | bash &>/dev/null||:; } &
cm "rustc" && { curl --proto '=https' --tlsv1.2 -fSL https://sh.rustup.rs --retry 3 --connect-timeout 10 | sh -s -- -y --default-toolchain stable &>/dev/null||:; } &
cm "uv" && { curl -fSL https://astral.sh/uv/install.sh --retry 3 --connect-timeout 10 | sh &>/dev/null||:; } &
wait
[[ ! -f /usr/share/keyrings/microsoft.gpg ]] && { curl -fSL https://packages.microsoft.com/keys/microsoft.asc --retry 3 --connect-timeout 10 | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg 2>&-||:; }
[[ ! -f /etc/apt/sources.list.d/vscode.sources ]] && sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF
{ pm "code" && { sudo apt update -qq &>/dev/null||:; sudo apt install -y code &>/dev/null||:; }; } &
{ type lshw >/dev/null && lshw -C display 2>&- | grep -q "NVIDIA" && { [[ ! -f /etc/apt/sources.list.d/graphics-drivers-ubuntu-ppa-noble.sources ]] && { sudo add-apt-repository -y ppa:graphics-drivers/ppa &>/dev/null||:; sudo apt update -qq &>/dev/null||:; }; pm "nvidia-driver-580" && sudo apt install -y nvidia-driver-580 &>/dev/null||:; }; } &
wait
lc "Development tools installed"
mkd "$HOME/.config/Code/User"
[[ ! -f "$HOME/.config/Code/User/settings.json" ]] && tee "$HOME/.config/Code/User/settings.json" >/dev/null <<EOF
{"[python]":{"editor.insertSpaces":true,"editor.tabSize":4},"chat.commandCenter.enabled":false,"editor.acceptSuggestionOnEnter":"off","editor.fontFamily":"'$FN', monospace","editor.fontLigatures":true,"editor.renderWhitespace":"all","editor.wordWrap":"off","extensions.ignoreRecommendations":true,"files.autoSave":"afterDelay","files.insertFinalNewline":true,"files.trimTrailingWhitespace":true,"telemetry.telemetryLevel":"off","terminal.integrated.fontFamily":"'$FN', monospace","window.newWindowDimensions":"maximized","workbench.editor.empty.hint":"hidden","workbench.startupEditor":"none"}
EOF
[[ -f "/tmp/default-firefox-profile.tar.xz" ]] && [[ ! -f "$HOME/snap/firefox/common/.mozilla/firefox/$FP/prefs.js" ]] && { tar -xJf "/tmp/default-firefox-profile.tar.xz" -C "$HOME/snap/firefox/common/.mozilla/firefox/$FP" --strip-components=1 2>&-||:; rm -f "/tmp/default-firefox-profile.tar.xz" 2>&-||:; }
[[ ! -f "$HOME/snap/firefox/common/.mozilla/firefox/profiles.ini" ]] && cat >"$HOME/snap/firefox/common/.mozilla/firefox/profiles.ini" <<EOF
[General]
StartWithLastProfile=1
Version=2
[Profile0]
Name=default
IsRelative=1
Path=$FP
Default=1
EOF
grep -q "^PS1=.*➔" "$HOME/.bashrc" 2>&- || { grep -v "^PS1=" "$HOME/.bashrc" > "$HOME/.bashrc.tmp" 2>&-||:; printf "PS1='\\\\[\\\\e[1;34m\\\\]\\\\w\\\\[\\\\e[0m\\\\] ➔ '\n" >> "$HOME/.bashrc.tmp" 2>&-||:; mv "$HOME/.bashrc.tmp" "$HOME/.bashrc" 2>&-||:; }
[[ -d "$HOME/.local/share/fnm" ]] && { export PATH="$HOME/.local/share/fnm:$PATH"; eval "$(fnm env --use-on-cd)" 2>&-||:; fnm install --lts &>/dev/null||:; fnm use lts-latest &>/dev/null||:; fnm default lts-latest &>/dev/null||:; npm config set fund false 2>&-||:; npm install -g npm@latest &>/dev/null||:; } &
[[ -f "$HOME/.cargo/env" ]] && { source "$HOME/.cargo/env" 2>&-||:; } &
[[ -f "$HOME/.local/bin/uv" ]] && { export PATH="$HOME/.local/bin:$PATH"; uv python install &>/dev/null||:; } &
li "Finalizing setup..."
wait
{ sudo apt clean &>/dev/null||:; } &
{ sudo apt autoclean &>/dev/null||:; } &
{ sudo apt autoremove --purge -y &>/dev/null||:; } &
wait
lc "Setup complete"
ET=$(date +%s); EL=$((ET - ST))
if [[ $EL -lt 60 ]]; then printf "Done in %ss\n" "$EL"
elif [[ $EL -lt 3600 ]]; then printf "Done in %sm %ss\n" "$((EL/60))" "$((EL%60))"
else printf "Done in %sh %sm %ss\n" "$((EL/3600))" "$(((EL%3600)/60))" "$((EL%60))"; fi
li "Applying terminal font..."
gs "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$TP/" "use-system-font" "false"
gs "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$TP/" "font" "'$FN'"
lc "Terminal font applied"
li "Reboot required for all changes to take effect."
