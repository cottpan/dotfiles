#!/usr/bin/env bash
# エラーがあったらそこで即終了、設定していない変数を使ったらエラーにする
set -euo pipefail

# is_arm という関数を用意しておく。毎回 uname -m を実行するのは莫迦らしいので、UNAME 環境変数で判断
is_arm() { test "$UNAME" == "arm64"; }

# アーキテクチャ名は UNAME に入れておく
UNAME=`uname -m`

# dotfiles の場所を設定
DOTPATH=$HOME/dotfiles

# Rosetta2 でターミナルを動かしている時には強制終了させる
if [ "$UNAME-$(arch -arm64 uname -m)" == "x86_64-arm64" ]; then
  echo "This script can not exec in Rosetta2 terminal"
  exit 1
fi

