#!/usr/bin/env bash
# エラーがあったらそこで即終了
set -eo pipefail
# Prevent commands misbehaving due to locale differences
export LC_ALL=C

# dotfiles の場所を設定
DOTPATH=$HOME/dotfiles
DOTFILES_GITHUB="https://github.com/cottpan/dotfiles.git"; export DOTFILES_GITHUB

# アーキテクチャ名は UNAME に入れておく
UNAME=$(uname -m)

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

# Ubuntu 本体と、その派生 (Linux Mint など) / Debian もまとめて見る
is_ubuntu() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "${ID:-}|${ID_LIKE:-}" in
            ubuntu\|* | debian\|* | *ubuntu* | *debian*) return 0 ;;
            *) return 1 ;;
        esac
    else
        return 1
    fi
}

# etc/init/linux 以下のどのディレクトリを使うか
linux_family() {
    if is_fedora ; then
        echo "fedora"
    elif is_ubuntu ; then
        echo "ubuntu"
    fi
}

is_arm() { 
    test "$UNAME" == "arm64"
}

is_rosseta2() {
    test "$UNAME-$(arch -arm64 uname -m)" == "x86_64-arm64"
}

dotfiles_download() {
    if [ -n "${CI:-}" ] ; then
        echo "Working on CI"
    elif [ -d "$DOTPATH" ]; then
        echo "error: $DOTPATH: already exists"
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

    if ! xcode-select -p > /dev/null 2>&1; then
        echo "Installing Xcode CLT..."
        echo "Please re-run after Xcode CLT installation is complete."
        xcode-select --install
    fi
elif is_linux ; then
    if is_fedora ; then
        echo "Fedora detected."
        if ! command -v git > /dev/null 2>&1; then
            echo "Installing git..."
            sudo dnf install -y git
        fi
    elif is_ubuntu ; then
        echo "Ubuntu detected."
        if ! command -v git > /dev/null 2>&1; then
            echo "Installing git..."
            sudo apt-get update
            sudo apt-get install -y git
        fi
    else
        echo "Unsupported Linux distribution: ${ID:-unknown}. (Fedora / Ubuntu) Abort."
        exit 1
    fi
else
    echo "Unsupported OS. Abort."
    exit 1
fi

dotfiles_download

if is_linux && [ -d "${DOTPATH}" ]; then
    prerequisites="${DOTPATH}/etc/init/linux/$(linux_family)/prerequisites.sh"
    if [ -f "$prerequisites" ]; then
        bash "$prerequisites"
    elif is_fedora ; then
        echo "Installing prerequisites..."
        sudo dnf install -y git make
    elif is_ubuntu ; then
        echo "Installing prerequisites..."
        sudo apt-get update
        sudo apt-get install -y git make
    fi
fi

if is_linux && ! command -v make > /dev/null 2>&1; then
    echo "error: make is required but not installed"
    exit 1
fi

cd "${DOTPATH}" && make install
cd "${DOTPATH}" && make deploy

# TODO: x64向けanyenvのフォルダ作成
# 再起動: exec $SHELL -l