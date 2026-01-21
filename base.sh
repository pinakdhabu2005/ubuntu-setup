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
    echo "Downloading script from: $url"
    curl -fsSL "$url" -o "$tmpfile"
    echo "Running script with: $interpreter"
    sudo "$interpreter" "$tmpfile"
    rm -f "$tmpfile"
}
download_and_run "https://is.gd/vscodeubuntu" sh
if ! command -v bash >/dev/null 2>&1; then
    echo "Error: 'bash' not found but required for DSBDA setup." >&2
    exit 1
fi
download_and_run "https://is.gd/ubuntufastfetch" sh
download_and_run "https://is.gd/pinakchrome" sh
download_and_run "https://is.gd/dsbdaubuntu" bash

echo "All steps completed successfully."
