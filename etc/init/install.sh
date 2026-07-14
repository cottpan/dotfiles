#!/usr/bin/env bash
# エラーがあったらそこで即終了、設定していない変数を使ったらエラーにする
set -eo pipefail
# Prevent commands misbehaving due to locale differences
export LC_ALL=C

# dotfiles の場所を設定
DOTPATH=$HOME/dotfiles

is_macos() {
    test "$(uname)" == "Darwin"
}

is_linux() {
    test "$(uname)" == "Linux"
}

is_fedora() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        test "${ID:-}" == "fedora"
    else
        return 1
    fi
}

if [ -n "$CI" ] ; then
    DOTPATH=$RUNNER_WORKSPACE/dotfiles
fi

if is_macos ; then
    echo "macOS detected. Calling macOS install scripts..."
    source ${DOTPATH}/etc/init/osx/install
    source ${DOTPATH}/etc/init/osx/change_defaults.sh
elif is_linux && is_fedora ; then
    echo "Fedora detected. Calling Fedora install scripts..."
    source ${DOTPATH}/etc/init/linux/fedora/install
else
    echo "Unsupported OS. Skipping OS-specific package installation."
fi

# dotfiles の .vimrc で dein を管理するため、dein-installer は使わない
if [ -z "$CI" ] ; then
    mkdir -p "$HOME/.vim/backup"
    dein_path="$HOME/.cache/dein/repos/github.com/Shougo/dein.vim"
    if [ ! -d "$dein_path" ]; then
        echo "Installing dein.vim..."
        mkdir -p "$(dirname "$dein_path")"
        git clone --depth 1 https://github.com/Shougo/dein.vim.git "$dein_path"
    fi
fi