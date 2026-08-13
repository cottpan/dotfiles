# shellcheck shell=sh
# この環境で実際に動くかを見る。読み取りのみで、設定を書き換えたりはしない。
#
# 道具が入っていない環境 (CI の静的チェックだけの回など) では素直に skip する。

suite "実行環境"

# --- PATH -------------------------------------------------------------------

if have zsh; then
    # .zshenv が PATH を組み立てるので、そこだけ読ませて確認する
    path_out=$(zsh -c ". '$DOTPATH/.zshenv' 2> /dev/null; print -r -- \$PATH" 2>&1)
    case ":$path_out:" in
        *":$HOME/bin:"*) ok "PATH に ~/bin が入る (.zshenv)" ;;
        *) fail "PATH に ~/bin が入る (.zshenv)" "$path_out" ;;
    esac
    case ":$path_out:" in
        *":$HOME/.local/bin:"*) ok "PATH に ~/.local/bin が入る (.zshenv)" ;;
        *) fail "PATH に ~/.local/bin が入る (.zshenv)" "$path_out" ;;
    esac
else
    skip "PATH の確認" "zsh が無い"
fi

# 実際のシェルから bin のコマンドが引けるか (デプロイ済みの環境のみ)
if [ -L "$HOME/bin" ] || [ -d "$HOME/bin" ]; then
    if have tmux-workspace; then
        ok "bin のコマンドが PATH から引ける (tmux-workspace)"
    else
        skip "bin のコマンドが PATH から引ける" "この shell の PATH に \$HOME/bin が無い"
    fi
else
    skip "bin のコマンドが PATH から引ける" "\$HOME/bin が未デプロイ"
fi

# --- bin のスクリプト -------------------------------------------------------

for file in $(git -C "$DOTPATH" ls-files 'bin/*'); do
    path="$DOTPATH/$file"
    [ -f "$path" ] || continue
    if [ -x "$path" ]; then
        ok "実行権限がある $file"
    else
        fail "実行権限がある $file" "chmod +x が漏れている"
    fi
    if is_binary "$path"; then
        skip "シェバンがある $file" "バイナリ"
        continue
    fi
    case $(head -1 "$path") in
        '#!'*) ok "シェバンがある $file" ;;
        *) fail "シェバンがある $file" "1 行目: $(head -1 "$path")" ;;
    esac
done

# --- 必要なコマンド ---------------------------------------------------------

# 無いと dotfiles の想定が崩れるもの
for cmd in zsh git make nvim tmux; do
    if have "$cmd"; then
        ok "$cmd が入っている"
    else
        fail "$cmd が入っている" "Brewfile / dnf の一覧を確認する"
    fi
done

# 各機能が要求するもの (無ければ機能が黙って落ちるので警告として見せる)
for cmd in rg fd jq gh entr python3 tree-sitter; do
    if have "$cmd"; then
        ok "$cmd が入っている"
    else
        skip "$cmd が入っている" "この環境には無い"
    fi
done

if [ "$(uname)" = "Darwin" ]; then
    for cmd in icalBuddy pbcopy; do
        if have "$cmd"; then
            ok "$cmd が入っている (macOS)"
        else
            skip "$cmd が入っている (macOS)" "この環境には無い"
        fi
    done
fi

# --- zsh --------------------------------------------------------------------

if have zsh; then
    # 対話シェルとして起動できるか (zplug の読み込みまで含む)
    if output=$(ZDOTDIR="$HOME" zsh -ic 'exit 0' 2>&1); then
        ok "zsh が対話シェルとして起動する"
    else
        fail "zsh が対話シェルとして起動する" "$output"
    fi
else
    skip "zsh の起動" "zsh が無い"
fi

# --- Neovim -----------------------------------------------------------------

if have nvim; then
    # 初回起動では lazy.nvim がプラグインの導入経過を出すので、
    # 「出力が無いこと」ではなく「エラーが出ていないこと」を見る
    output=$(nvim --headless -c 'sleep 2' -c 'qa' 2>&1)
    if printf '%s' "$output" | grep -qE '^E[0-9]+:|Error|エラー'; then
        fail "nvim がエラーなく起動する" "$output"
    else
        ok "nvim がエラーなく起動する"
    fi

    # lazy.nvim のロックファイルが壊れていないか
    if have python3; then
        check "lazy-lock.json が JSON として読める" python3 -c \
            "import json; json.load(open('$DOTPATH/.config/nvim/lazy-lock.json'))"
    else
        skip "lazy-lock.json の検証" "python3 が無い"
    fi

    # 宣言したプラグインが実際に入っているか
    plugin_check='lua
        local lazy = require("lazy")
        local missing = {}
        for _, p in ipairs(lazy.plugins()) do
          if not p._.installed then table.insert(missing, p.name) end
        end
        if #missing > 0 then
          io.stderr:write("未導入: " .. table.concat(missing, ", ") .. "\n")
          vim.cmd("cq")
        end'
    if output=$(nvim --headless -c "$plugin_check" -c 'qa' 2>&1); then
        ok "宣言したプラグインが全て入っている"
    else
        fail "宣言したプラグインが全て入っている" "$output"
    fi
else
    skip "nvim の起動" "nvim が無い"
fi

# --- tmux -------------------------------------------------------------------

if have tmux; then
    socket="dotfiles-test-rt-$$"
    tmux -L "$socket" -f "$DOTPATH/.tmux.conf" new-session -d -x 80 -y 24 2> /dev/null
    prefix=$(tmux -L "$socket" show-options -gv prefix 2> /dev/null)
    if [ "$prefix" = "C-q" ]; then
        ok "tmux の prefix が C-q になる"
    else
        fail "tmux の prefix が C-q になる" "prefix=$prefix"
    fi

    # send-prefix が割り当たっていないこと (C-z 二度押しで suspend した問題の回帰確認)
    if tmux -L "$socket" list-keys -T prefix 2> /dev/null | grep -q "send-prefix"; then
        fail "send-prefix が割り当てられていない" "$(tmux -L "$socket" list-keys -T prefix | grep send-prefix)"
    else
        ok "send-prefix が割り当てられていない"
    fi

    term=$(tmux -L "$socket" show-options -gv default-terminal 2> /dev/null)
    if [ "$term" = "tmux-256color" ]; then
        ok "default-terminal が tmux-256color"
    else
        fail "default-terminal が tmux-256color" "default-terminal=$term"
    fi
    tmux -L "$socket" kill-server 2> /dev/null || true
else
    skip "tmux の設定値" "tmux が無い"
fi

# --- チートシート -----------------------------------------------------------

for target in tmux nvim; do
    if output=$("$DOTPATH/bin/cheatsheet" "$target" --list 2>&1) && [ -n "$output" ]; then
        ok "チートシートが出る ($target)"
    else
        fail "チートシートが出る ($target)" "$output"
    fi
done

# 列が欠けていないか (セクション・キー・概要は必須)
if have python3; then
    check "チートシートの表が壊れていない" python3 -c "
import sys, pathlib
for name in ('tmux', 'nvim'):
    path = pathlib.Path('$DOTPATH/etc/cheatsheet/%s.tsv' % name)
    for number, line in enumerate(path.read_text(encoding='utf-8').splitlines(), 1):
        if not line.strip() or line.startswith('#'):
            continue
        fields = line.split('\t')
        if len(fields) < 3 or not all(fields[:3]):
            sys.exit('%s:%d 列が足りない: %s' % (path.name, number, line))
"
else
    skip "チートシートの表の検証" "python3 が無い"
fi

if have tmux; then
    socket="dotfiles-test-cheat-$$"
    tmux -L "$socket" -f "$DOTPATH/.tmux.conf" new-session -d -x 80 -y 24 2> /dev/null
    assigned=$(tmux -L "$socket" list-keys -T prefix 2> /dev/null | grep -c "cheatsheet")
    if [ "$assigned" -ge 2 ]; then
        ok "チートシートのキーが割り当たっている (tmux / nvim)"
    else
        fail "チートシートのキーが割り当たっている (tmux / nvim)" "見つかった数: $assigned"
    fi
    tmux -L "$socket" kill-server 2> /dev/null || true
else
    skip "チートシートのキー割り当て" "tmux が無い"
fi

# --- bin のスモークテスト ---------------------------------------------------

if have tmux; then
    check "tmux-workspace --help が動く" "$DOTPATH/bin/tmux-workspace" --help
else
    skip "tmux-workspace --help" "tmux が無い"
fi

if have python3; then
    # 空の JSON を渡しても落ちないこと (フックは何も出力しない)
    # TMUX_PANE を空にして「tmux の外から呼ばれた」状態を作る
    output=$(printf '%s' '{}' | env TMUX_PANE= "$DOTPATH/bin/claude-tmux-title" 2>&1)
    smoke_status=$?
    if [ $smoke_status -eq 0 ] && [ -z "$output" ]; then
        ok "claude-tmux-title が tmux 外で黙って終わる"
    else
        fail "claude-tmux-title が tmux 外で黙って終わる" "$output"
    fi

    if have tmux && [ -n "${TMUX:-}" ]; then
        if output=$("$DOTPATH/bin/tmux-status-right" --once 2>&1); then
            ok "tmux-status-right --once が出力を返す"
        else
            fail "tmux-status-right --once が出力を返す" "$output"
        fi
    else
        skip "tmux-status-right --once" "tmux の中で実行していない"
    fi
else
    skip "python 製スクリプトのスモークテスト" "python3 が無い"
fi
