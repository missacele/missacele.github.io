#!/bin/bash

FIREFOX_DIR="$HOME/snap/firefox/common/.mozilla/firefox"
BACKUP_DIR="default-firefox-profile"

show_usage() {
    echo "Firefox Profile Backup Tool"
    echo ""
    echo "Usage:"
    echo "  $0 [profile_name]"
    echo ""
    echo "Examples:"
    echo "  $0"
    echo "  $0 trzbyug1.default"
    echo ""
    echo "Output:"
    echo "  default-firefox-profile/"
    echo "  default-firefox-profile.tar.xz"
}

backup_profile() {
    local profile_dir="$1"

    if [ -z "$profile_dir" ]; then
        if [ -f "$FIREFOX_DIR/profiles.ini" ]; then
            profile_dir=$(grep -A3 "Default=1" "$FIREFOX_DIR/profiles.ini" | grep "Path=" | cut -d'=' -f2)
            if [ -z "$profile_dir" ]; then
                profile_dir=$(grep "Path=" "$FIREFOX_DIR/profiles.ini" | head -1 | cut -d'=' -f2)
            fi
        fi
    fi

    if [ -z "$profile_dir" ]; then
        echo "No profile found. Please specify profile directory."
        show_usage
        return 1
    fi

    if [ ! -d "$FIREFOX_DIR/$profile_dir" ]; then
        echo "Profile directory not found: $profile_dir"
        echo "Available profiles:"
        ls -la "$FIREFOX_DIR" | grep "^d" | grep -v "^\.$\|^\.\.$" || echo "  None found"
        return 1
    fi

    echo "Firefox Profile Backup"

    echo "Backing up profile: $profile_dir"

    echo "Closing Firefox..."
    sleep 1

    rm -rf "$BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"

    echo "Creating clean template..."

    if [ -f "$FIREFOX_DIR/$profile_dir/prefs.js" ]; then
        grep -v -E "(normandy\.user_id|contextual-services\.contextId|push\.userAgentID|nimbus\.profileId|telemetry\.cachedClientID|telemetry\.cachedProfileGroupID|toolkit\.profiles\.storeID|lastUpdate|last_check|lastDownload|lastInstall|timestamp|profileCreationTime|lastColdStartupCheck|last_update_seconds|last_success)" "$FIREFOX_DIR/$profile_dir/prefs.js" > "$BACKUP_DIR/prefs.js"

        if ! grep -q "dom.security.https_only_mode" "$BACKUP_DIR/prefs.js"; then
            echo 'user_pref("dom.security.https_only_mode", true);' >> "$BACKUP_DIR/prefs.js"
        fi
    fi

    cp "$FIREFOX_DIR/$profile_dir/user.js" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$FIREFOX_DIR/$profile_dir/xulstore.json" "$BACKUP_DIR/" 2>/dev/null
    cp "$FIREFOX_DIR/$profile_dir/addons.json" "$BACKUP_DIR/" 2>/dev/null
    cp "$FIREFOX_DIR/$profile_dir/extensions.json" "$BACKUP_DIR/" 2>/dev/null
    cp "$FIREFOX_DIR/$profile_dir/extension-preferences.json" "$BACKUP_DIR/" 2>/dev/null

    if [ -d "$FIREFOX_DIR/$profile_dir/extensions" ]; then
        cp -r "$FIREFOX_DIR/$profile_dir/extensions" "$BACKUP_DIR/"
    fi

    if [ -d "$FIREFOX_DIR/$profile_dir/extension-data" ]; then
        cp -r "$FIREFOX_DIR/$profile_dir/extension-data" "$BACKUP_DIR/"
    fi

    cp "$FIREFOX_DIR/$profile_dir/handlers.json" "$BACKUP_DIR/" 2>/dev/null
    cp "$FIREFOX_DIR/$profile_dir/containers.json" "$BACKUP_DIR/" 2>/dev/null
    cp "$FIREFOX_DIR/$profile_dir/broadcast-listeners.json" "$BACKUP_DIR/" 2>/dev/null
    cp "$FIREFOX_DIR/$profile_dir/extension-settings.json" "$BACKUP_DIR/" 2>/dev/null
    cp "$FIREFOX_DIR/$profile_dir/addonStartup.json.lz4" "$BACKUP_DIR/" 2>/dev/null

    cp "$FIREFOX_DIR/$profile_dir/content-prefs.sqlite" "$BACKUP_DIR/" 2>/dev/null

    if [ -d "$FIREFOX_DIR/$profile_dir/storage/default/moz-extension" ]; then
        mkdir -p "$BACKUP_DIR/storage/default"
        cp -r "$FIREFOX_DIR/$profile_dir/storage/default/moz-extension" "$BACKUP_DIR/storage/default/" 2>/dev/null
    fi

    local file_count=$(find "$BACKUP_DIR" -type f | wc -l)
    echo "Template created: $file_count files"

    echo "Creating compressed archive..."
    rm -f default-firefox-profile.tar.xz
    tar -cJf default-firefox-profile.tar.xz "$BACKUP_DIR/"
    local archive_size=$(ls -lh default-firefox-profile.tar.xz | awk '{print $5}')

    rm -rf "$BACKUP_DIR"

    echo ""
    echo "Backup completed successfully!"
    echo "Compressed archive: default-firefox-profile.tar.xz ($archive_size, $file_count files)"
    echo ""
    echo "Ready for:"
    echo "   Upload to GitHub repository"
    echo "   Use with ./restore-firefox-profile.sh"
    echo "   Integration with automation scripts"
    echo ""
}

if ! command -v firefox &>/dev/null; then
    echo "Firefox snap not found. Install it first:"
    echo "   sudo snap install firefox"
    exit 1
fi

if [ ! -d "$HOME/snap/firefox" ]; then
    echo "Firefox snap directory not found. Run Firefox once to initialize."
    exit 1
fi

backup_profile "$1"
