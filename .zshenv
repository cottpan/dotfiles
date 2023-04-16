#ログインシェル、インタラクティブシェル、シェルスクリプト、どれでも常に必要な設定を定義する
#zsh が起動して、必ず最初に読み込まれる設定ファイル
export PYENV_ROOT="$HOME/.anyenv/envs/pyenv"
export MINT_PATH="$HOME/.mint"
export MINT_LINK_PATH="$MINT_PATH/bin"
export CPPFLAGS="-I/opt/homebrew/opt/openjdk@11/include"
export ANDROID_HOME="$HOME/Library/Android/sdk"


path=(
    $HOME/bin(N-/)
    $HOME/.mint/bin(N-/)
    $HOME/.cargo/bin(N-/)
    $PYENV_ROOT/bin(N-/)
    /opt/homebrew/opt/openjdk@11/bin(N-/)
    $ANDROID_HOME/platform-tools(N-/)
    $ANDROID_HOME/emulator(N-/)
    $path
)
