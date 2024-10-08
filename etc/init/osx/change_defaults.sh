#!/usr/bin/env bash
# エラーがあったらそこで即終了、設定していない変数を使ったらエラーにする
set -euo pipefail
# Prevent commands misbehaving due to locale differences
export LC_ALL=C

# ブート時のサウンドの無効化 (寂しい気もしますが煩いので消しています)
sudo nvram SystemAudioVolume=" "

# スクロールバーの常時表示
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

# デフォルトで隠しファイルを表示する
defaults write com.apple.finder AppleShowAllFiles -bool true
# 全ての拡張子のファイルを表示
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
# ステータスバーを表示
defaults write com.apple.finder ShowStatusBar -bool true
# パスバーを表示
defaults write com.apple.finder ShowPathbar -bool true
# 検索時にデフォルトでカレントディレクトリを検索
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# USBやネットワークストレージに.DS_Storeファイルを作成しない
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
# Show the ~/Library folder
chflags nohidden ~/Library

# スクリーンショットの撮影時に影を含めない
defaults write com.apple.screencapture disable-shadow -boolean true
# スクリーンショットの保存先を変更
defaults write com.apple.screencapture location ~/Pictures/Screenshots

for app in "Dock" \
	"Finder" \
	"SystemUIServer"; do
	killall "${app}" &> /dev/null
done
