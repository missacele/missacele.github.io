set -euo pipefail

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
  ubuntu-desktop-minimal \
  ubuntu-docs \
  ubuntu-report \
  whoopsie \
  yelp
do
  dpkg -s "$pkg" >/dev/null 2>&1 && \
    sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y "$pkg"
done

sudo systemctl daemon-reload

# ----------

sudo apt-get update

missing_packages=()
for pkg in \
  apt-transport-https \
  aria2 \
  build-essential \
  curl \
  libssl-dev \
  tree
do
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    missing_packages+=("$pkg")
  fi
done

if [ ${#missing_packages[@]} -gt 0 ]; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "${missing_packages[@]}"
fi

if apt-get -s upgrade | grep -q '^Inst '; then
  sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
fi

if snap refresh --list 2>/dev/null | grep -q 'available'; then
  sudo snap refresh
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

# ----------

if fc-list ":family=FiraCode Nerd Font" | grep -q .; then
  :
else
  temp_dir="$(mktemp -d)"
  pushd "$temp_dir" >/dev/null

  url_latest="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz"
  aria2c -x8 -s8 -o FiraCode.tar.xz "$url_latest"

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
  sudo install -d -m0755 /etc/apt/keyrings
  aria2c -x8 -s8 -d /tmp -o docker.gpg.asc https://download.docker.com/linux/ubuntu/gpg
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg /tmp/docker.gpg.asc
  sudo chmod a+r /etc/apt/keyrings/docker.gpg
  rm -f /tmp/docker.gpg.asc
fi
if [ ! -f /etc/apt/sources.list.d/docker.sources ]; then
  update_needed=true
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
  sudo apt-get update
fi

if ! dpkg -s docker-ce >/dev/null 2>&1; then
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
  aria2c -x8 -s8 -d /tmp -o default-firefox-profile.tar.xz "https://missacele.github.io/assets/default-firefox-profile.tar.xz"
  tar -xJf /tmp/default-firefox-profile.tar.xz -C "$firefox_base/$firefox_profile" --strip-components=1
  rm -f /tmp/default-firefox-profile.tar.xz
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
  sudo DEBIAN_FRONTEND=noninteractive apt-get remove -y code
fi

aria2c -x8 -s8 -d /tmp -o code.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64"
sudo DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/code.deb
sudo apt-get install -f -y
rm -f /tmp/code.deb

code --install-extension PKief.material-icon-theme
code --install-extension biomejs.biome
code --install-extension bradlc.vscode-tailwindcss
code --install-extension Vue.volar

mkdir -p "$HOME/.config/Code/User"
cat > "$HOME/.config/Code/User/settings.json" <<EOF
{
  "chat.commandCenter.enabled": false,
  "chat.disableAIFeatures": true,
  "editor.acceptSuggestionOnEnter": "off",
  "editor.fontFamily": "'FiraCode Nerd Font', monospace",
  "editor.fontLigatures": true,
  "editor.renderWhitespace": "all",
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
  aria2c -x8 -s8 -o install.sh https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh
  bash install.sh
  rm -f install.sh
  \. "$HOME/.nvm/nvm.sh"
  nvm install 24
  npm config set fund false
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
