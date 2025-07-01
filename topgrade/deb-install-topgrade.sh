#!/bin/bash

# Script to install Topgrade on Debian(oids).
# Also sets config file to disable updates for Containers and Firmware.

# MARK: Vars & Precheck
GH_USER=topgrade-rs # GitHub user that owns the repo
GH_REPO=topgrade # Name of the GitHub repo
GH_VERSION=latest # Can be used to specify a version (default: latest)

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Who is running this script?
USER=$(logname)
if [ -z "$USER" ]; then
    echo "Could not determine the user running this script."
    exit 2
else
    echo "Running as user: $USER"
fi

# What's the user's home?
USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
if [ -z "$USER_HOME" ]; then
    echo "Could not determine the home directory for user $USER."
    exit 3
    else
    echo "User home directory: $USER_HOME"
fi

# Create a temporary directory for downloading and cd into it
tmp_dir=$(mktemp -d -t tg-XXXXXXXXXX) && cd "$tmp_dir" || {
    echo "Failed to create a temporary directory."
    exit 6
}

# Ensure the temporary directory is cleaned up on exit
trap 'rm -rf "$tmp_dir"' EXIT
echo "Using temporary directory: $tmp_dir"

# Get CPU architecture
ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then
    ARCH="amd64"
    archiveName="x86_64-unknown-linux-gnu.tar.gz"
elif [ "$ARCH" == "aarch64" ] || [ "$ARCH" == "arm64" ]; then
    ARCH="aarch64"
    archiveName="aarch64-unknown-linux-gnu.tar.gz"
elif [ "$ARCH" == "armv7l" ]; then
    ARCH="armhf"
    archiveName="armv7-unknown-linux-gnueabihf.tar.gz"
else
    echo "Unsupported architecture: $ARCH"
    exit 4
fi

echo "Detected architecture: $ARCH"
echo "Using archive name: $archiveName"


# MARK: Main
# Assemble the download URL
if [ "$GH_VERSION" == "latest" ]; then
    GH_VERSION=$(curl -s "https://api.github.com/repos/$GH_USER/$GH_REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | tr -d 'v')
    if [ -z "$GH_VERSION" ]; then
        echo "Failed to fetch the latest version from GitHub."
        exit 5
    fi
    echo "Latest version: $GH_VERSION"
else
    echo "Using specified version: $GH_VERSION"
fi

# Download Topgrade from GitHub
# Reference: https://stackoverflow.com/questions/46060010/download-github-release-with-curl
wget https://github.com/$GH_USER/$GH_REPO/releases/download/v$GH_VERSION/topgrade-v$GH_VERSION-$archiveName \
-O "$tmp_dir/$GH_REPO.tar.gz" && \
tar -xzvf "$tmp_dir/$GH_REPO.tar.gz"

# Move it to /usr/local/bin
mv "$tmp_dir/topgrade" "/usr/local/bin/"

# Create the config directory if it doesn't exist and set permissions
if [ ! -d "$USER_HOME/.config/topgrade.d" ]; then
    mkdir -p "$USER_HOME/.config/topgrade.d"
    chown "$USER:$USER" "$USER_HOME/.config/topgrade.d"
fi

# Write config to file ~/.config/topgrade.d/disable.toml
# and set file ownership.
cat > $USER_HOME/.config/topgrade.d/disable.toml <<EOF
[misc]
# Run `sudo -v` to cache credentials at the start of the run
# This avoids a blocking password prompt in the middle of an unattended run
# (default: false)
# pre_sudo = false

# Sudo command to be used
# sudo_command = "sudo"

# Disable specific steps - same options as the command line flag
disable = ["containers", "firmware"]
EOF

chown "$USER:$USER" "$USER_HOME/.config/topgrade.d/disable.toml"

exit 0
