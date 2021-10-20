#ログインシェル、インタラクティブシェル、シェルスクリプト、どれでも常に必要な設定を定義する
#zsh が起動して、必ず最初に読み込まれる設定ファイル
path=(
    $HOME/bin(N-/)
    $HOME/.mint/bin(N-/)
    /opt/homebrew/opt/openjdk@11/bin(N-/)
    $path
)