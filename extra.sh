#!/usr/bin/env sh
set -eu
if ! command -v apt >/dev/null 2>&1; then
    echo "Error: 'apt' not found. This script is intended for Debian/Ubuntu systems." >&2
    exit 1
fi
if ! command -v sudo >/dev/null 2>&1; then
    echo "Error: 'sudo' not found. Please install sudo or run commands as root manually." >&2
    exit 1
fi
echo "Updating package index and installing curl..."
sudo apt update
sudo apt install -y curl

if ! command -v curl >/dev/null 2>&1; then
    echo "Error: curl installation failed." >&2
    exit 1
fi
download_and_run() {
    url="$1"
    interpreter="$2"

    tmpfile=$(mktemp /tmp/remote-installer.XXXXXX) || {
        echo "Error: mktemp failed." >&2
        exit 1
    }

    echo "Downloading system script from: $url"
    curl -fsSL "$url" -o "$tmpfile"

    echo "Running script with sudo $interpreter"
    sudo "$interpreter" "$tmpfile"

    rm -f "$tmpfile"
}
download_and_run "https://is.gd/vscodeubuntu" sh
if ! command -v bash >/dev/null 2>&1; then
    echo "Error: 'bash' not found but required for DSBDA setup." >&2
    exit 1
fi
download_and_run "https://is.gd/dsbdaubuntu" bash
download_and_run "https://is.gd/pinakchrome" sh
download_and_run "https://is.gd/ubuntufastfetch" sh
echo "Preparing to apply VS Code settings for all users..."
settings_script=$(mktemp /tmp/vscode-settings.XXXXXX) || {
    echo "Error: mktemp failed for VS Code settings." >&2
    exit 1
}
echo "Downloading VS Code settings script..."
curl -fsSL "https://is.gd/vscodelinux" -o "$settings_script"
chmod 644 "$settings_script"
apply_vscode_settings_for_user() {
    local target_user="$1"
    local user_home
    user_home=$(getent passwd "$target_user" | cut -d: -f6)
    if [ -d "$user_home" ]; then
        echo ">> Applying VS Code settings for user: $target_user"
        
        if sudo -u "$target_user" sh "$settings_script"; then
            echo "   Success for $target_user"
        else
            echo "   Warning: Failed to apply settings for $target_user"
        fi
    fi
}
user_list=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd)
if [ -n "${SUDO_USER:-}" ]; then
    user_list="$user_list
$SUDO_USER"
fi
echo "$user_list" | sort -u | while read -r user; do
    if [ -n "$user" ]; then
        apply_vscode_settings_for_user "$user"
    fi
done
rm -f "$settings_script"
echo "All steps completed successfully."
