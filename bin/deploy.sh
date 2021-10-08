#!/usr/bin/env bash

# Fail on unset variables and command errors
set -ue -o pipefail

# Prevent commands misbehaving due to locale differences
export LC_ALL=C

if !(type "brew" > /dev/null 2>&1); then
    echo "install Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "already installed: Homebrew"
fi

if !(type "git" > /dev/null 2>&1); then
    echo "install git..."
    brew install git
else
    echo "already installed: git"
fi

# Set DOTPATH as default variable
if [ -z "${DOTPATH:-}" ]; then
    DOTPATH=~/dotfiles; export DOTPATH
fi
DOTFILES_GITHUB="https://github.com/cottpan/dotfiles.git"; export DOTFILES_GITHUB
# checkout dotfile repo
dotfiles_download() {
    if [ -d "$DOTPATH" ]; then
        echo "error: $DOTPATH: already exists"
        exit 1
    fi
    echo "Downloading dotfiles..."

    git clone --recursive "$DOTFILES_GITHUB" "$DOTPATH"
}
dotfiles_download

cd ${DOTPATH} && make install

brewfile_path=~/.Brewfile
if [ -e $brewfile_path ]; then
  brew bundle --file $brewfile_path
fi