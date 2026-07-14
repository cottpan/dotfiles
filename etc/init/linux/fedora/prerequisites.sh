#!/usr/bin/env bash
set -eo pipefail
export LC_ALL=C

echo "Installing Fedora prerequisites..."
sudo dnf install -y git make

if ! command -v make > /dev/null 2>&1; then
    echo "error: make is required but not available after dnf install"
    exit 1
fi
