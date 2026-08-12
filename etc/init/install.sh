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

# 素の vim 用 (.vimrc の backupdir / directory)
if [ -z "$CI" ] ; then
    mkdir -p "$HOME/.vim/backup"
fi

# Neovim: lazy.nvim は .config/nvim/init.lua が自前で bootstrap するので、
# ここでは初回のプラグイン同期だけ済ませておく
# (mason の LSP サーバは headless では入らないので、初回の nvim 起動時に導入される)
if [ -z "$CI" ] && command -v nvim > /dev/null 2>&1 ; then
    echo "Syncing Neovim plugins..."
    nvim --headless "+Lazy! sync" +qa
fi

# tmux: TPM (プラグインマネージャ) と宣言済みプラグインを用意する
# (.tmux.conf 側にも同じ bootstrap があるので、どちらか一方が動けばよい)
if [ -z "$CI" ] && command -v tmux > /dev/null 2>&1 ; then
    tpm_path="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$tpm_path" ]; then
        echo "Installing tpm..."
        git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_path"
    fi
    if [ -x "$tpm_path/bin/install_plugins" ]; then
        echo "Installing tmux plugins..."
        "$tpm_path/bin/install_plugins"
    fi
fi