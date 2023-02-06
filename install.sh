#!/usr/bin/env bash
# エラーがあったらそこで即終了、設定していない変数を使ったらエラーにする
set -euo pipefail

# dotfiles の場所を設定
DOTPATH=$HOME/dotfiles

if [ "$(uname)" == "Darwin" ]; then
	echo "macOS detected. "
else 
	echo "Not macOS!"
	exit 1
fi

# Rosetta2 でターミナルを動かしている時には強制終了させる
if [ "$UNAME-$(arch -arm64 uname -m)" == "x86_64-arm64" ]; then
	echo "This script can not exec in Rosetta2 terminal"
	exit 1
fi

xcode-select --install

if [ ! -d ~/dotfiles ]; then
  cd ~
  echo "Cloning dotfiles..."
  git clone https://github.com/cottpan/dotfiles.git
else
  echo "dotfiles already cloned."
fi

cd ${DOTPATH}
make install
make deploy