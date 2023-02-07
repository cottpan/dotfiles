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

if ! [ -z $CI ] ; then
	DOTPATH=$RUNNER_WORKSPACE/dotfiles
fi

if is_macos ; then
	echo "macOS detected. Calling macOS install scripts..."
    source ${DOTPATH}/etc/init/osx/install
    source ${DOTPATH}/etc/init/osx/change_defaults.sh
else 
	echo "Not macOS! Abort."
	exit 1
fi
