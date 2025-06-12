#!/bin/bash

# Script to install Topgrade on Debian.
# Also sets config file to disable updates for Containers and Firmware.

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Who is running this script?
USER=$(who am i | awk '{print $1}')
if [ -z "$USER" ]; then
    echo "Could not determine the user running this script."
    exit 2
else
    echo "Running as user: $USER"
fi

# ...and search for the home directory of that user
USER_HOME=$(getent passwd "$USER" | cut -d: -f6)
if [ -z "$USER_HOME" ]; then
    echo "Could not determine the home directory for user $USER."
    exit 3
    else
    echo "User home directory: $USER_HOME"
fi

# Download Topgrade wihtout GLIBC_2.39 dependencies
wget -nv "https://github.com/SteveLauC/topgrade/releases/download/v16.0.3_glibc_2.36/topgrade"

# Make it executable
chmod +x topgrade

# Move it to /usr/local/bin
mv topgrade /usr/local/bin/

# Create the config directory if it doesn't exist and set permissions
if [ ! -d "$USER_HOME/.config/topgrade.d" ]; then
    mkdir -p "$USER_HOME/.config/topgrade.d"
    chown "$USER:$USER" "$USER_HOME/.config/topgrade.d"
fi

# Write config to file ~/.config/topgrade.d/disable.toml
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

exit 0