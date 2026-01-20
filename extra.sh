#!/usr/bin/env sh
# POSIX-compliant setup script for:
# - Installing curl
# - Installing VS Code
# - Running DSBDA Python setup
# - Installing Google Chrome
# - Applying extra VS Code settings

set -eu

# Ensure we're on a Debian/Ubuntu-like system
if ! command -v apt >/dev/null 2>&1; then
    echo "Error: 'apt' not found. This script is intended for Debian/Ubuntu systems." >&2
    exit 1
fi

# Ensure sudo exists
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

# Function to download a script to a temp file and run it with sudo
download_and_run() {
    url="$1"
    interpreter="$2"

    tmpfile=$(mktemp /tmp/remote-installer.XXXXXX) || {
        echo "Error: mktemp failed." >&2
        exit 1
    }

    echo "Downloading script from: $url"
    curl -fsSL "$url" -o "$tmpfile"

    echo "Running script with sudo $interpreter"
    sudo "$interpreter" "$tmpfile"

    rm -f "$tmpfile"
}

# 1) Install VS Code
download_and_run "https://is.gd/vscodeubuntu" sh

# 2) Python DSBDA all setup (requires bash as per original command)
if ! command -v bash >/dev/null 2>&1; then
    echo "Error: 'bash' not found but required for DSBDA setup." >&2
    exit 1
fi
download_and_run "https://is.gd/dsbdaubuntu" bash

# 3) Install Google Chrome
download_and_run "https://is.gd/pinakchrome" sh

# 4) Extra VS Code settings (run as current user, no sudo)
echo "Applying extra VS Code settings..."
tmpfile_extra=$(mktemp /tmp/vscode-settings.XXXXXX) || {
    echo "Error: mktemp failed for VS Code settings." >&2
    exit 1
}

curl -fsSL "https://is.gd/vscodelinux" -o "$tmpfile_extra"
sh "$tmpfile_extra"
rm -f "$tmpfile_extra"

echo "All steps completed successfully."
