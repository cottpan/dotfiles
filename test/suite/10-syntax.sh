# shellcheck shell=sh
# 構文チェック。副作用なしで、どの環境でも走らせられるもの。
#
# チェッカはシェバンを見て振り分ける。新しいスクリプトを bin/ に置いても、
# ここを触らずに対象へ入るようにしておく。

suite "構文チェック"

# シェバンから使うべきチェッカを決める。判定できなければ空を返す
checker_for() {
    file=$1
    line=$(head -1 "$file" 2> /dev/null)
    case $line in
        *zsh*) echo zsh ;;
        *bash*) echo bash ;;
        *python3*) echo python3 ;;
        '#!/bin/sh' | *' sh') echo sh ;;
        *)
            # シェバンが無いものは拡張子と場所で判断する
            case $file in
                *.lua) echo lua ;;
                *.zsh | */.zshrc | */.zshenv | */.zprofile) echo zsh ;;
                */.zsh/functions/* | */.zsh/worktree-hooks/*) echo zsh ;;
                *.sh) echo sh ;;
                *) echo "" ;;
            esac
            ;;
    esac
}

syntax_check() {
    file=$1
    rel=${file#"$DOTPATH"/}
    if is_binary "$file"; then
        skip "$rel" "バイナリ"
        return
    fi
    case $(checker_for "$file") in
        zsh)
            if have zsh; then
                check "zsh -n $rel" zsh -n "$file"
            else
                skip "zsh -n $rel" "zsh が無い"
            fi
            ;;
        bash)
            check "bash -n $rel" bash -n "$file"
            ;;
        sh)
            check "sh -n $rel" sh -n "$file"
            ;;
        python3)
            if have python3; then
                check "python3 構文 $rel" python3 -m py_compile "$file"
            else
                skip "python3 構文 $rel" "python3 が無い"
            fi
            ;;
        lua)
            : # lua はまとめて後段でチェックする
            ;;
        *)
            skip "$rel" "チェッカ不明"
            ;;
    esac
}

# 対象ファイルの一覧 (git 管理下のみ。etc/colortheme は外部のテーマなので見ない)
script_files() {
    git -C "$DOTPATH" ls-files \
        'bin/*' 'etc/init/*' 'test/*' 'install.sh' \
        '.zshrc' '.zshenv' '.zprofile' '.zsh/*' 2> /dev/null
}

for file in $(script_files); do
    path="$DOTPATH/$file"
    [ -f "$path" ] || continue
    case $file in
        # *.disabled は worktree hooks 側が読み飛ばす置き場のドキュメント
        *.md | *.json | *.disabled) continue ;;
    esac
    syntax_check "$path"
done

# 生成された .pyc を残さない
rm -rf "$DOTPATH/bin/__pycache__" 2> /dev/null || true

# Neovim の Lua 設定
if have nvim; then
    lua_files=$(git -C "$DOTPATH" ls-files '.config/nvim/**/*.lua')
    if [ -n "$lua_files" ]; then
        # 読み込めない (構文が壊れている) ファイルがあれば cq で異常終了させる
        lua_check='lua
            local bad = {}
            for _, f in ipairs(vim.fn.glob(vim.fn.getcwd() .. "/.config/nvim/**/*.lua", false, true)) do
              local chunk, err = loadfile(f)
              if not chunk then table.insert(bad, err) end
            end
            if #bad > 0 then
              io.stderr:write(table.concat(bad, "\n") .. "\n")
              vim.cmd("cq")
            end'
        if output=$(cd "$DOTPATH" && nvim --headless -c "$lua_check" -c 'qa' 2>&1); then
            ok "Lua 構文 .config/nvim/**/*.lua"
        else
            fail "Lua 構文 .config/nvim/**/*.lua" "$output"
        fi
    fi
else
    skip "Lua 構文 .config/nvim" "nvim が無い"
fi

# tmux の設定。専用ソケットで読み込ませて、エラー出力が無いことを見る
if have tmux; then
    socket="dotfiles-test-$$"
    output=$(tmux -L "$socket" -f "$DOTPATH/.tmux.conf" new-session -d -x 80 -y 24 2>&1)
    status=$?
    tmux -L "$socket" kill-server 2> /dev/null || true
    if [ $status -eq 0 ] && [ -z "$output" ]; then
        ok "tmux 設定の読み込み .tmux.conf"
    else
        fail "tmux 設定の読み込み .tmux.conf" "$output"
    fi
else
    skip "tmux 設定の読み込み" "tmux が無い"
fi

# mise の設定 (TOML)
if have python3; then
    check "TOML 構文 .config/mise/config.toml" python3 -c \
        "import tomllib,sys; tomllib.load(open('$DOTPATH/.config/mise/config.toml','rb'))"
else
    skip "TOML 構文 .config/mise/config.toml" "python3 が無い"
fi

# ダッシュボードの設定 (YAML)。PyYAML は標準では入っていないので、あるときだけ見る
if have python3 && python3 -c "import yaml" 2> /dev/null; then
    check "YAML 構文 .config/wtf/config.yml" python3 -c \
        "import yaml; yaml.safe_load(open('$DOTPATH/.config/wtf/config.yml', encoding='utf-8'))"
else
    skip "YAML 構文 .config/wtf/config.yml" "PyYAML が無い"
fi

# ShellCheck は入っていれば走らせる (必須にはしない)
if have shellcheck; then
    for file in $(script_files); do
        path="$DOTPATH/$file"
        [ -f "$path" ] || continue
        case $(checker_for "$path") in
            sh | bash) check "shellcheck $file" shellcheck -x "$path" ;;
        esac
    done
else
    skip "shellcheck" "shellcheck が無い"
fi
