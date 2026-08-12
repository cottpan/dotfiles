#ログインシェル、インタラクティブシェル、シェルスクリプト、どれでも常に必要な設定を定義する
#zsh が起動して、必ず最初に読み込まれる設定ファイル
export PYENV_ROOT="$ANYENV_ROOT/envs/pyenv"
export MINT_PATH="$HOME/.mint"
export MINT_LINK_PATH="$MINT_PATH/bin"
export BUN_INSTALL="$HOME/.bun"

# エディタは Neovim (無い環境では vim にフォールバック)
if command -v nvim > /dev/null 2>&1; then
  export EDITOR=nvim
  export VISUAL=nvim
elif command -v vim > /dev/null 2>&1; then
  export EDITOR=vim
  export VISUAL=vim
fi

if [ "$(uname)" = "Darwin" ]; then
  export CPPFLAGS="-I/opt/homebrew/opt/openjdk@11/include"
  export ANDROID_HOME="$HOME/Library/Android/sdk"
elif [ "$(uname)" = "Linux" ]; then
  export ANDROID_HOME="$HOME/Android/Sdk"
fi

path=(
    $HOME/.local/bin(N-/)
    $HOME/bin(N-/)
    $HOME/.mint/bin(N-/)
    $HOME/.cargo/bin(N-/)
    $PYENV_ROOT/bin(N-/)
    /opt/homebrew/opt/openjdk@11/bin(N-/)
    $ANDROID_HOME/platform-tools(N-/)
    $ANDROID_HOME/emulator(N-/)
    $BUN_INSTALL/bin(N-/)
    $path
)
if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi
