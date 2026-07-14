#!/usr/bin/env bash
# エラーがあったらそこで即終了
set -eo pipefail
# Prevent commands misbehaving due to locale differences
export LC_ALL=C

# dotfiles の場所を設定
DOTPATH=$HOME/dotfiles
DOTFILES_GITHUB="https://github.com/cottpan/dotfiles.git"; export DOTFILES_GITHUB

# アーキテクチャ名は UNAME に入れておく
UNAME=`uname -m`

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

is_arm() { 
    test "$UNAME" == "arm64"
}

is_rosseta2() {
    test "$UNAME-$(arch -arm64 uname -m)" == "x86_64-arm64"
}

dotfiles_download() {
    if [ -d "$DOTPATH" ]; then
        echo "error: $DOTPATH: already exists"
    elif [ -n "$CI" ] ; then
        echo "Working on CI"
    else
        echo "Downloading dotfiles..."
        git clone --recursive "$DOTFILES_GITHUB" "$DOTPATH"
    fi
}

is_clt_installed() {
    xcode-select -p > /dev/null 2>&1
}

if [ -n "$CI" ] ; then
    DOTPATH=$RUNNER_WORKSPACE/dotfiles
fi

if is_macos ; then
    # Rosetta2 でターミナルを動かしている時には強制終了させる
    if ! is_arm ; then
        echo "x86 Processor Detected"
        if is_rosseta2 ; then
            echo "This script can not exec in Rosetta2 terminal. Abort."
            exit 1
        fi
    else
        echo "ARM Processor Detected."
    fi

    if !( xcode-select -p > /dev/null 2>&1 ); then
        echo "Installing Xcode CLT..."
        echo "Please re-run after Xcode CLT installation is complete."
        xcode-select --install
    fi
elif is_linux ; then
    if is_fedora ; then
        echo "Fedora detected."
        fedora_packages=()
        command -v git > /dev/null 2>&1 || fedora_packages+=(git)
        command -v make > /dev/null 2>&1 || fedora_packages+=(make)
        if [ ${#fedora_packages[@]} -gt 0 ]; then
            echo "Installing prerequisites: ${fedora_packages[*]}"
            sudo dnf install -y "${fedora_packages[@]}"
        fi
    else
        echo "Unsupported Linux distribution. Abort."
        exit 1
    fi
else
    echo "Unsupported OS. Abort."
    exit 1
fi

dotfiles_download

cd ${DOTPATH} && make install
cd ${DOTPATH} && make deploy

# TODO: x64向けanyenvのフォルダ作成
# 再起動: exec $SHELL -l