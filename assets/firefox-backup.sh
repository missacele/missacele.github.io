#!/bin/bash

firefox_base="$HOME/snap/firefox/common/.mozilla/firefox"
backup_file="firefox-backup.tar.xz"
temp_dir="/tmp/firefox-backup"

if [ ! -d "$firefox_base" ]; then
  echo "Firefox profile directory not found: $firefox_base" >&2
  exit 1
fi

if [ -f "$firefox_base/profiles.ini" ] && grep -q '^Path=' "$firefox_base/profiles.ini"; then
  firefox_profile="$(awk -F= '/^Path=/ {print $2; exit}' "$firefox_base/profiles.ini")"
else
  echo "No Firefox profile found" >&2
  exit 1
fi

profile_path="$firefox_base/$firefox_profile"
if [ ! -d "$profile_path" ]; then
  echo "Firefox profile directory not found: $profile_path" >&2
  exit 1
fi

mkdir -p "$temp_dir"

echo "Backing up Firefox profile: $firefox_profile"

backup_files=(
  "prefs.js"
  "extensions/"
  "xulstore.json"
  "content-prefs.sqlite"
  "addonStartup.json.lz4"
  "broadcast-listeners.json"
  "extension-settings.json"
  "extension-preferences.json"
  "handlers.json"
  "addons.json"
  "containers.json"
  "extensions.json"
)

success=true
for file in "${backup_files[@]}"; do
  if [ -e "$profile_path/$file" ]; then
    cp -r "$profile_path/$file" "$temp_dir/" || success=false
  fi
done

if [ "$success" = true ]; then
  echo "Creating backup archive..."
  tar -cJf "$backup_file" -C "$temp_dir" .
  echo "Backup created: $backup_file"
  echo "Size: $(du -h "$backup_file" | cut -f1)"
  echo "Backup located: ./$backup_file"
else
  echo "Backup failed - some files could not be copied" >&2
  exit 1
fi

rm -rf "$temp_dir"
echo "Firefox profile backup completed successfully!"