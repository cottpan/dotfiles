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

is_linux() {
    test "$(uname)" == "Linux"
}

is_fedora() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        test "${ID:-}" == "fedora"
    else
        return 1
    fi
}

# Ubuntu 本体と、その派生 (Linux Mint など) / Debian もまとめて見る
is_ubuntu() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        case "${ID:-}|${ID_LIKE:-}" in
            ubuntu\|* | debian\|* | *ubuntu* | *debian*) return 0 ;;
            *) return 1 ;;
        esac
    else
        return 1
    fi
}

if [ -n "$CI" ] ; then
    DOTPATH=$RUNNER_WORKSPACE/dotfiles
fi

if is_macos ; then
    echo "macOS detected. Calling macOS install scripts..."
    source "${DOTPATH}/etc/init/osx/install"
    # 使い捨ての CI ランナーで macOS の環境設定を書き換えても意味が無く、
    # sudo nvram が失敗して全体が止まることもあるので CI では飛ばす
    if [ -z "${CI:-}" ] ; then
        source "${DOTPATH}/etc/init/osx/change_defaults.sh"
    fi
elif is_linux && is_fedora ; then
    echo "Fedora detected. Calling Fedora install scripts..."
    source "${DOTPATH}/etc/init/linux/fedora/install"
elif is_linux && is_ubuntu ; then
    echo "Ubuntu detected. Calling Ubuntu install scripts..."
    source "${DOTPATH}/etc/init/linux/ubuntu/install"
else
    echo "Unsupported OS. Skipping OS-specific package installation."
fi

# 素の vim 用 (.vimrc の backupdir / directory)
if [ -z "$CI" ] ; then
    mkdir -p "$HOME/.vim/backup"
fi

# tree-sitter の CLI。nvim-treesitter の main ブランチはパーサのビルドをこれに任せる
# ので、無いと :TSUpdate が ENOENT で落ちる。macOS は Brewfile の tree-sitter-cli で
# 入るが、dnf にも apt にも使えるものが無い (あっても main が要求するより古い) ので、
# Linux では公式のリリースを ~/.local/bin に置く
install_tree_sitter_cli() {
    local asset url
    case "$(uname -m)" in
        x86_64) asset="tree-sitter-linux-x64.gz" ;;
        aarch64 | arm64) asset="tree-sitter-linux-arm64.gz" ;;
        *)
            echo "warning: no official tree-sitter build for $(uname -m)"
            return 1
            ;;
    esac

    url="https://github.com/tree-sitter/tree-sitter/releases/latest/download/${asset}"
    echo "Installing the tree-sitter CLI from ${url}..."
    mkdir -p "$HOME/.local/bin"
    if ! curl -fsSL "$url" | gunzip > "$HOME/.local/bin/tree-sitter"; then
        rm -f "$HOME/.local/bin/tree-sitter"
        echo "warning: failed to download the tree-sitter CLI"
        return 1
    fi
    chmod +x "$HOME/.local/bin/tree-sitter"
    hash -r
}

if [ -z "$CI" ] && is_linux && ! command -v tree-sitter > /dev/null 2>&1 ; then
    install_tree_sitter_cli || true
fi

# uv (Python のパッケージ / プロジェクト管理)。macOS は Brewfile で入るが、dnf / apt
# の版は古かったり無かったりするので、Linux では公式のインストーラを使う。
# 素で走らせると ~/.zshenv や ~/.zshrc (dotfiles へのシンボリックリンク) に PATH の
# 設定を書き足してリポジトリを汚すので、それは止めて ~/.local/bin にだけ置く
# (~/.local/bin は .zshenv が PATH に入れている)
install_uv() {
    echo "Installing uv..."
    if ! curl -fsSL https://astral.sh/uv/install.sh |
        INSTALLER_NO_MODIFY_PATH=1 UV_INSTALL_DIR="$HOME/.local/bin" sh; then
        echo "warning: failed to install uv"
        return 1
    fi
    hash -r
}

if [ -z "$CI" ] && is_linux && ! command -v uv > /dev/null 2>&1 ; then
    install_uv || true
fi

# harlequin (ターミナルの SQL クライアント)。公式が uv での導入を勧めているので、
# uv tool として隔離した環境に入れる (実行ファイルは ~/.local/bin に張られる)。
# 接続先のアダプタは extras で足す。DuckDB / SQLite は本体に入っている
HARLEQUIN_PACKAGE="harlequin[postgres]"

# 初回の macOS では brew を入れた直後で、この shell の PATH にまだ載っていない。
# Fedora も ~/.local/bin を PATH に入れていないので、既知の置き場も見て探す
find_uv() {
    local candidate
    if command -v uv > /dev/null 2>&1; then
        command -v uv
        return 0
    fi
    for candidate in "$HOME/.local/bin/uv" /opt/homebrew/bin/uv /usr/local/bin/uv; do
        if [ -x "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

install_harlequin() {
    local uv
    if ! uv=$(find_uv); then
        echo "warning: uv not found; skipping harlequin"
        return 1
    fi
    echo "Installing harlequin..."
    if ! "$uv" tool install "$HARLEQUIN_PACKAGE"; then
        echo "warning: failed to install harlequin"
        return 1
    fi
    hash -r
}

if [ -z "$CI" ] && ! command -v harlequin > /dev/null 2>&1 &&
    [ ! -x "$HOME/.local/bin/harlequin" ] ; then
    install_harlequin || true
fi

# Neovim: lazy.nvim は .config/nvim/init.lua が自前で bootstrap するので、
# ここでは初回のプラグイン同期だけ済ませておく
# (mason の LSP サーバは headless では入らないので、初回の nvim 起動時に導入される)
if [ -z "$CI" ] && command -v nvim > /dev/null 2>&1 ; then
    echo "Syncing Neovim plugins..."
    nvim --headless "+Lazy! sync" +qa
fi

# tmux: TPM (プラグインマネージャ) と宣言済みプラグインを用意する
# (.tmux.conf 側にも同じ bootstrap があるので、どちらか一方が動けばよい)
if [ -z "$CI" ] && command -v tmux > /dev/null 2>&1 ; then
    tpm_path="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$tpm_path" ]; then
        echo "Installing tpm..."
        git clone --depth 1 https://github.com/tmux-plugins/tpm "$tpm_path"
    fi
    if [ -x "$tpm_path/bin/install_plugins" ]; then
        echo "Installing tmux plugins..."
        "$tpm_path/bin/install_plugins"
    fi

    # continuum は tmux サーバの起動時に復元を試みる。保存が一度も無い新しい
    # マシンでは resurrect が "Tmux resurrect file not found!" と出してくるので、
    # 空の保存を置いて黙らせる (次の自動保存が普通に上書きしていく)
    resurrect_dir="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
    if [ -d "$HOME/.tmux/resurrect" ]; then
        # resurrect は旧い置き場が既にあればそちらを使う
        resurrect_dir="$HOME/.tmux/resurrect"
    fi
    if [ ! -e "$resurrect_dir/last" ]; then
        echo "Seeding an empty tmux-resurrect save..."
        mkdir -p "$resurrect_dir"
        resurrect_seed="tmux_resurrect_$(date +%Y%m%dT%H%M%S).txt"
        : > "$resurrect_dir/$resurrect_seed"
        ln -sfn "$resurrect_seed" "$resurrect_dir/last"
    fi
fi