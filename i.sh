set -euo pipefail

log_info() { printf "\e[1;34m[INFO]\e[0m %s\n" "$1" >&2; }
log_warn() { printf "\e[1;33m[WARN]\e[0m %s\n" "$1" >&2; }
log_error() { printf "\e[1;31m[ERROR]\e[0m %s\n" "$1" >&2; }

safe_download() {
  local -r url="$1"
  local -r filename="$2"
  local -r temp_dir="${3:-/tmp}"

  [ -f "$temp_dir/$filename" ] && rm -f "$temp_dir/$filename"

  if ! aria2c -x8 -s8 -d "$temp_dir" -o "$filename" "$url"; then
    log_error "Download failed: $url"
    exit 1
  fi

  if [ ! -f "$temp_dir/$filename" ]; then
    log_error "Downloaded file not found: $temp_dir/$filename"
    exit 1
  fi
}

check_and_install_packages() {
  local -r packages=("$@")
  local missing_packages=()

  for pkg in "${packages[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      missing_packages+=("$pkg")
    fi
  done

  if [ ${#missing_packages[@]} -gt 0 ]; then
    log_info "Installing packages: ${missing_packages[*]}"
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing_packages[@]}"
  fi
}

check_and_remove_packages() {
  local -r packages=("$@")

  for pkg in "${packages[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
      log_info "Removing package: $pkg"
      sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y "$pkg"
    fi
  done
}

# ----------

sudo -v
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" 2>/dev/null || exit
done 2>/dev/null &
SUDO_KEEPALIVE_PID=$!
trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || : ' EXIT

# ----------

powerprofilesctl set performance >/dev/null 2>&1 || :

# ----------

gsettings set org.gnome.desktop.interface clock-format 12h
gsettings set org.gnome.desktop.interface clock-show-date false
gsettings set org.gnome.desktop.interface color-scheme prefer-dark
gsettings set org.gnome.desktop.interface gtk-theme Yaru-dark
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.desktop.privacy hide-identity true
gsettings set org.gnome.desktop.privacy old-files-age 0
gsettings set org.gnome.desktop.privacy recent-files-max-age 1
gsettings set org.gnome.desktop.privacy remember-app-usage false
gsettings set org.gnome.desktop.privacy remember-recent-files false
gsettings set org.gnome.desktop.privacy remove-old-temp-files true
gsettings set org.gnome.desktop.privacy remove-old-trash-files true
gsettings set org.gnome.desktop.privacy show-full-name-in-top-bar false
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.desktop.sound allow-volume-above-100-percent true
gsettings set org.gnome.desktop.wm.preferences button-layout appmenu:minimize,maximize,close
gsettings set org.gnome.mutter center-new-windows true
gsettings set org.gnome.nautilus.preferences show-create-link true
gsettings set org.gnome.nautilus.preferences show-delete-permanently true
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
gsettings set org.gnome.settings-daemon.plugins.power lid-close-ac-action nothing
gsettings set org.gnome.settings-daemon.plugins.power lid-close-battery-action nothing
gsettings set org.gnome.shell.extensions.dash-to-dock always-center-icons true
gsettings set org.gnome.shell.extensions.dash-to-dock autohide false
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0
gsettings set org.gnome.shell.extensions.dash-to-dock click-action minimize
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide false
gsettings set org.gnome.shell.extensions.dash-to-dock scroll-action cycle-windows
gsettings set org.gnome.shell.extensions.dash-to-dock show-apps-at-top true
gsettings set org.gnome.shell.extensions.dash-to-dock show-mounts false
gsettings set org.gnome.shell.extensions.dash-to-dock show-trash false
gsettings set org.gnome.shell.extensions.ding show-home false
gsettings set org.gnome.shell favorite-apps "['org.gnome.Nautilus.desktop','org.gnome.Terminal.desktop','firefox_firefox.desktop','code.desktop']"

# ----------

mkdir -p "$HOME/.local/share/applications"
for file in \
  /usr/share/applications/gnome-language-selector.desktop \
  /usr/share/applications/info.desktop \
  /usr/share/applications/nm-connection-editor.desktop \
  /usr/share/applications/software-properties-drivers.desktop \
  /usr/share/applications/software-properties-gtk.desktop
do
  dest="$HOME/.local/share/applications/$(basename "$file")"
  if [ ! -f "$dest" ] || ! cmp -s "$file" "$dest"; then
    cp "$file" "$dest"
  fi
  if ! grep -q '^Hidden=true' "$dest" 2>/dev/null; then
    if grep -q '^Hidden=' "$dest" 2>/dev/null; then
      sed -i 's/^Hidden=.*/Hidden=true/' "$dest"
    else
      printf 'Hidden=true\n' >> "$dest"
    fi
  fi
done

# ----------

sudo systemctl stop whoopsie.path whoopsie.service >/dev/null 2>&1 || :
sudo systemctl mask whoopsie.path whoopsie.service >/dev/null 2>&1 || :

if snap list 2>/dev/null | grep -qw firmware-updater; then
  sudo snap remove --purge firmware-updater
fi

if [ -d /etc/systemd/user/default.target.wants ]; then
  sudo rm -f /etc/systemd/user/default.target.wants/* || :
  sudo rmdir --ignore-fail-on-non-empty /etc/systemd/user/default.target.wants || :
fi

installed_packages=()
for pkg in \
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
  gnome-user-docs \
  seahorse \
  ubuntu-docs \
  ubuntu-report \
  whoopsie \
  yelp
do
  dpkg -s "$pkg" >/dev/null 2>&1 && installed_packages+=("$pkg")
done

if [ ${#installed_packages[@]} -gt 0 ]; then
  log_info "Removing packages: ${installed_packages[*]}"
  sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y "${installed_packages[@]}"
fi

sudo systemctl daemon-reload

# ----------

sudo apt-get update

check_and_install_packages apt-transport-https aria2 build-essential curl libssl-dev tree

if apt-get -s upgrade | grep -q '^Inst '; then
  log_info "Upgrading system packages"
  sudo DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y
fi

updates=$(snap refresh --list 2>&1)
if [[ "$updates" == "All snaps up to date." ]]; then
    log_info "No snap updates available"
else
    log_info "Refreshing snap packages"
    sudo snap refresh
fi

# ----------

wallpaper_file="$HOME/.local/share/wallpapers/backiee-246388-landscape.jpg"
wallpaper_uri="file://$wallpaper_file"

if [ -f "$wallpaper_file" ]; then
  log_info "Wallpaper already exists"
else
  log_info "Downloading wallpaper"
  mkdir -p "$HOME/.local/share/wallpapers"
  safe_download "https://missacele.github.io/assets/backiee-246388-landscape.jpg" "backiee-246388-landscape.jpg"
  mv /tmp/backiee-246388-landscape.jpg "$wallpaper_file"
fi

gsettings set org.gnome.desktop.background picture-uri "$wallpaper_uri"
gsettings set org.gnome.desktop.background picture-uri-dark "$wallpaper_uri"

# ----------

if fc-list ":family=FiraCode Nerd Font" | grep -q .; then
  log_info "FiraCode Nerd Font already installed"
else
  log_info "Installing FiraCode Nerd Font"
  temp_dir="$(mktemp -d)"
  pushd "$temp_dir" >/dev/null

  url_latest="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz"
  safe_download "$url_latest" "FiraCode.tar.xz" "$temp_dir"

  tar -xJf FiraCode.tar.xz
  mkdir -p "$HOME/.local/share/fonts/NerdFonts"
  find . -type f -name "*.ttf" -exec cp -f {} "$HOME/.local/share/fonts/NerdFonts/" \;
  fc-cache -f

  popd >/dev/null
  rm -rf "$temp_dir"
fi
font='FiraCode Nerd Font'

profiles_list="$(gsettings get org.gnome.Terminal.ProfilesList list 2>/dev/null || echo "[]")"
uuids=()
while read -r u; do uuids+=("$u"); done < <(echo "$profiles_list" | grep -oE "[a-f0-9-]{36}" || :)
uuid=""
for u in "${uuids[@]}"; do
  name="$(gsettings get "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$u/" visible-name 2>/dev/null || :)"
  [ "${name//\'/}" = "One Dark" ] && uuid="$u" && break
done
if [ -z "$uuid" ]; then
  uuid="$(uuidgen)"
  uuids+=("$uuid")
  new_list="[$(printf "'%s'," "${uuids[@]}" | sed 's/,$//')]"
  gsettings set org.gnome.Terminal.ProfilesList list "$new_list"
  gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$uuid/" visible-name "One Dark"
fi
profile_path="org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$uuid/"
gsettings set "$profile_path" background-color '#1E2127'
gsettings set "$profile_path" bold-color '#ABB2BF'
gsettings set "$profile_path" bold-color-same-as-fg true
gsettings set "$profile_path" cursor-background-color '#5C6370'
gsettings set "$profile_path" cursor-colors-set true
gsettings set "$profile_path" cursor-foreground-color '#1E2127'
gsettings set "$profile_path" font "$font 11"
gsettings set "$profile_path" foreground-color '#ABB2BF'
gsettings set "$profile_path" highlight-background-color '#3A3F4B'
gsettings set "$profile_path" highlight-colors-set true
gsettings set "$profile_path" highlight-foreground-color '#ABB2BF'
gsettings set "$profile_path" palette "['#000000', '#E06C75', '#98C379', '#D19A66', '#61AFEF', '#C678DD', '#56B6C2', '#ABB2BF', '#5C6370', '#E06C75', '#98C379', '#D19A66', '#61AFEF', '#C678DD', '#56B6C2', '#FFFFFF']"
gsettings set "$profile_path" scrollback-lines 20000
gsettings set "$profile_path" use-system-font false
gsettings set "$profile_path" use-theme-colors false
gsettings set org.gnome.Terminal.ProfilesList default "$uuid"

# ----------

if sudo lshw -class display 2>/dev/null | grep -q "NVIDIA"; then
  if ! dpkg -s nvidia-driver-580 >/dev/null 2>&1; then
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nvidia-driver-580
  fi
fi

# ----------

update_needed=false

if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  update_needed=true
  log_info "Installing Docker GPG key"
  sudo install -d -m0755 /etc/apt/keyrings
  safe_download "https://download.docker.com/linux/ubuntu/gpg" "docker.gpg.asc"
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg /tmp/docker.gpg.asc
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  rm -f /tmp/docker.gpg.asc
fi
if [ ! -f /etc/apt/sources.list.d/docker.sources ]; then
  update_needed=true
  log_info "Adding Docker repository"
  sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<'EOF'
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: noble
Components: stable
Architectures: amd64
Signed-By: /etc/apt/keyrings/docker.gpg
EOF
fi

if [ "$update_needed" = true ]; then
  log_info "Updating package lists for Docker repository"
  sudo apt-get update
fi

if ! dpkg -s docker-ce >/dev/null 2>&1; then
  log_info "Installing Docker CE"
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce
fi
sudo groupadd -f docker
id -nG "$USER" | grep -qw docker || sudo usermod -aG docker "$USER"

# ----------

firefox_base="$HOME/snap/firefox/common/.mozilla/firefox"
mkdir -p "$firefox_base"

if [ -f "$firefox_base/profiles.ini" ] && grep -q '^Path=' "$firefox_base/profiles.ini"; then
  firefox_profile="$(awk -F= '/^Path=/ {print $2; exit}' "$firefox_base/profiles.ini")"
else
  firefox_profile="default.$(date +%s)"
fi
mkdir -p "$firefox_base/$firefox_profile"

if [ ! -f "$firefox_base/$firefox_profile/prefs.js" ]; then
  log_info "Setting up Firefox profile"
  safe_download "https://missacele.github.io/assets/firefox-backup.tar.xz" "firefox-backup.tar.xz"
  tar -xJf /tmp/firefox-backup.tar.xz -C "$firefox_base/$firefox_profile" --strip-components=1
  rm -f /tmp/firefox-backup.tar.xz
fi

desired_ini="$(cat <<EOF
[General]
StartWithLastProfile=1
Version=2

[Profile0]
Name=default
IsRelative=1
Path=$firefox_profile
Default=1
EOF
)"
if [ ! -f "$firefox_base/profiles.ini" ] || ! cmp -s <(printf "%s" "$desired_ini") "$firefox_base/profiles.ini"; then
  printf "%s" "$desired_ini" > "$firefox_base/profiles.ini"
fi

# ----------

if dpkg -s code >/dev/null 2>&1; then
  log_info "VS Code already installed"
else
  log_info "Installing VS Code"
  safe_download "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" "code.deb"
  sudo DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/code.deb
  sudo apt-get install -f -y
  rm -f /tmp/code.deb
fi

if ! dpkg -s code >/dev/null 2>&1 || ! code --list-extensions | grep -q "PKief.material-icon-theme"; then
  log_info "Installing VS Code extensions"
  code --install-extension PKief.material-icon-theme
  code --install-extension qwtel.sqlite-viewer
else
  log_info "VS Code extensions already installed"
fi

mkdir -p "$HOME/.config/Code/User"
cat > "$HOME/.config/Code/User/settings.json" <<EOF
{
  "breadcrumbs.enabled": false,
  "chat.commandCenter.enabled": false,
  "chat.disableAIFeatures": true,
  "editor.acceptSuggestionOnEnter": "off",
  "editor.fontFamily": "'FiraCode Nerd Font', monospace",
  "editor.fontLigatures": true,
  "editor.minimap.enabled": false,
  "editor.renderWhitespace": "all",
  "editor.stickyScroll.enabled": false,
  "editor.wordWrap": "off",
  "extensions.ignoreRecommendations": true,
  "files.autoSave": "afterDelay",
  "files.insertFinalNewline": true,
  "files.trimTrailingWhitespace": true,
  "telemetry.telemetryLevel": "off",
  "terminal.integrated.fontFamily": "'FiraCode Nerd Font', monospace",
  "window.commandCenter": false,
  "window.newWindowDimensions": "maximized",
  "workbench.editor.empty.hint": "hidden",
  "workbench.iconTheme": "material-icon-theme",
  "workbench.startupEditor": "none"
}
EOF

# ----------

if [ ! -d "$HOME/.nvm" ]; then
  log_info "Installing NVM"
  nvm_latest_version="$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep '"tag_name":' | cut -d'"' -f4)"
  if [ -z "$nvm_latest_version" ]; then
    log_error "Failed to fetch latest NVM version from GitHub API"
    exit 1
  fi
  log_info "Using NVM version: $nvm_latest_version"
  safe_download "https://raw.githubusercontent.com/nvm-sh/nvm/$nvm_latest_version/install.sh" "install.sh"
  bash /tmp/install.sh
  rm -f /tmp/install.sh
  \. "$HOME/.nvm/nvm.sh"
  nvm install 24
  npm config set fund false
else
  log_info "NVM already installed"
fi

# ----------

sqlite_dir="$HOME/.local/bin"
sqlite_tools=(
  "sqldiff"
  "sqlite3"
  "sqlite3_analyzer"
  "sqlite3_rsync"
)

needs_install=false

for tool in "${sqlite_tools[@]}"; do
  if [ ! -f "$sqlite_dir/$tool" ]; then
    needs_install=true
    break
  fi
done

if [ "$needs_install" = true ]; then
  log_info "Installing SQLite tools"
  mkdir -p "$sqlite_dir"
  safe_download "https://sqlite.org/2025/sqlite-tools-linux-x64-3510000.zip" "sqlite-tools.zip"

  unzip -o /tmp/sqlite-tools.zip -d /tmp

  cp /tmp/sqlite3 /tmp/sqldiff /tmp/sqlite3_analyzer /tmp/sqlite3_rsync "$sqlite_dir/" 2>/dev/null || {
    log_error "SQLite tools extraction failed - files not found"
    exit 1
  }

  rm -f /tmp/sqlite-tools.zip /tmp/sqlite3 /tmp/sqldiff /tmp/sqlite3_analyzer /tmp/sqlite3_rsync

  chmod +x "$sqlite_dir"/*
else
  log_info "SQLite tools already installed"
fi

export PATH="$sqlite_dir:$PATH"

if ! grep -q "export PATH=\"$sqlite_dir" "$HOME/.bashrc" 2>/dev/null; then
  echo "export PATH=\"$sqlite_dir:\$PATH\"" >> "$HOME/.bashrc"
fi

if ! grep -q "export PATH=\"$sqlite_dir" "$HOME/.profile" 2>/dev/null; then
  echo "export PATH=\"$sqlite_dir:\$PATH\"" >> "$HOME/.profile"
fi

# ----------

if sudo find /var/cache/apt/archives -maxdepth 1 -type f -name '*.deb' -print -quit 2>/dev/null | grep -q .; then
  sudo apt-get clean
fi

if sudo apt-get -s autoclean 2>/dev/null | grep -q '^Del '; then
  sudo apt-get autoclean
fi

if sudo apt-get -s autoremove --purge 2>/dev/null | grep -q '^Remv '; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get autoremove --purge -y
fi

if [ -f /var/run/reboot-required ]; then
  echo -e "\e[1;31mReboot required for all changes to take effect.\e[0m"
else
  echo -e "\e[1;32mNo reboot required. System is fully up to date.\e[0m"
fi
