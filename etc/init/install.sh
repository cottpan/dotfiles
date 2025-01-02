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

if [ -n "$CI" ] ; then
    DOTPATH=$RUNNER_WORKSPACE/dotfiles
fi

if is_macos ; then
    echo "macOS detected. Calling macOS install scripts..."
    source ${DOTPATH}/etc/init/osx/install
    source ${DOTPATH}/etc/init/osx/change_defaults.sh
else 
    echo "Not macOS! Abort."
fi

# Deinのインストールスクリプトが対話型のため、CIでは無効にする
set +u
if [ -z "$CI" ] ; then
    mkdir -p $HOME/.vim/backup
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/Shougo/dein-installer.vim/master/installer.sh)"
    rm $HOME/.vimrc
    mv $HOME/.vimrc.pre-dein-vim $HOME/.vimrc
fi
set -u