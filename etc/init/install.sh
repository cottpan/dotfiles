#!/usr/bin/env bash
# エラーがあったらそこで即終了、設定していない変数を使ったらエラーにする
set -euo pipefail

# dotfiles の場所を設定
DOTPATH=$HOME/dotfiles

if [[ "$(uname)" == "Darwin" ]]; then
	echo "macOS detected. Calling macOS install scripts..."
    source ${DOTPATH}/etc/init/osx/install
    source ${DOTPATH}/etc/init/osx/change_defaults.sh
else 
	echo "Not macOS!"
	exit 1
fi