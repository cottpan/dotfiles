#!/usr/bin/env bash
set -eo pipefail
export LC_ALL=C

# apt は tzdata などで対話プロンプトを出すので黙らせておく
export DEBIAN_FRONTEND=noninteractive

echo "Installing Ubuntu prerequisites..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl git make

if ! command -v make > /dev/null 2>&1; then
    echo "error: make is required but not available after apt-get install"
    exit 1
fi
