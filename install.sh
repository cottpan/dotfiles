#!/usr/bin/env bash
# エラーがあったらそこで即終了、設定していない変数を使ったらエラーにする
set -euo pipefail

# dotfiles の場所を設定
DOTPATH=$HOME/dotfiles

# アーキテクチャ名は UNAME に入れておく
UNAME=`uname -m`

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

if ![ xcode-select -p > /dev/null 2>&1 ]; then
  # Install homebrew in Intel Mac or M1 Mac on Rosetta2
  echo "Installing Xcode CLT..."
  xcode-select --install
fi

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