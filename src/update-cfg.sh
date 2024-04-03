#!/bin/sh

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# Check if the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root" >&2
    exit 1
fi

# Ensure /etc/osmocom exists and remove all existing files
mkdir -p /etc/osmocom/
rm -rf /etc/osmocom/*

# Copy configuration files to /etc/osmocom
cp -r "$SCRIPT_DIR/../etc/osmocom/"* /etc/osmocom/
