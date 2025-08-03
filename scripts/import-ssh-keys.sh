#!/bin/bash

# Exit on error
set -e

# Detect current user
CURRENT_USER=$(whoami)
echo "[*] Running as user: $CURRENT_USER"

# Ask for SSH source path
read -p "Enter the FULL path of the source .ssh folder: " SOURCE_SSH
if [ ! -d "$SOURCE_SSH" ]; then
    echo "[-] Source directory does not exist: $SOURCE_SSH"
    exit 1
fi

# Ask for destination path (default: /home/$CURRENT_USER/.ssh)
read -p "Enter the FULL path of the destination .ssh folder [Default: /home/$CURRENT_USER/.ssh]: " DEST_SSH
DEST_SSH="${DEST_SSH:-/home/$CURRENT_USER/.ssh}"

# Confirm
echo "[+] Copying from: $SOURCE_SSH"
echo "[+] Copying to:   $DEST_SSH"
read -p "Proceed? (y/n): " CONFIRM
[[ "$CONFIRM" != [yY] ]] && echo "Aborted." && exit 0

# Copy with sudo
echo "[*] Copying .ssh folder..."
sudo cp -r "$SOURCE_SSH" "$DEST_SSH"

# Change ownership
echo "[*] Changing ownership..."
sudo chown -R "$CURRENT_USER:$CURRENT_USER" "$DEST_SSH"

# Set permissions
echo "[*] Setting permissions..."
chmod 700 "$DEST_SSH"
chmod 600 "$DEST_SSH"/*

# Test SSH connection
echo "[*] Testing SSH connection with GitHub..."
ssh -T git@github.com

echo "[✓] SSH key setup completed successfully!"
