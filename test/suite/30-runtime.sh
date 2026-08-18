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
        fail "$cmd が入っている" "Brewfile / dnf / apt の一覧を確認する"
    fi
done

# 各機能が要求するもの (無ければ機能が黙って落ちるので警告として見せる)
for cmd in rg fd jq gh entr python3 uv harlequin btop tree-sitter wtfutil glow; do
    if have "$cmd"; then
        ok "$cmd が入っている"
    else
        skip "$cmd が入っている" "この環境には無い"
    fi
done

# mise で入れるもの。shims は PATH に入れていない (対話シェルでは .zshrc の
# mise activate が通す) ので、この shell からは mise 経由で見る
if have mise; then
    for cmd in hunk jnv lazydocker yazi; do
        if mise which "$cmd" > /dev/null 2>&1; then
            ok "$cmd が入っている (mise)"
        else
            skip "$cmd が入っている (mise)" "この環境には無い"
        fi
    done
else
    skip "mise のツール" "mise が無い"
fi

# gh の拡張 (gh dash)
if have gh; then
    if gh extension list 2> /dev/null | grep -q "gh-dash"; then
        ok "gh-dash が入っている (gh 拡張)"
    else
        skip "gh-dash が入っている (gh 拡張)" "この環境には無い"
    fi
else
    skip "gh の拡張" "gh が無い"
fi

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

    # ダッシュボードに d を使ったので、デタッチが D に残っていること
    if tmux -L "$socket" list-keys -T prefix 2> /dev/null | grep -q "prefix *D *detach-client"; then
        ok "デタッチが D に割り当たっている"
    else
        fail "デタッチが D に割り当たっている" "$(tmux -L "$socket" list-keys -T prefix | grep detach-client)"
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

    # ポップアップで開くもの (ダッシュボード / デイリーメモ / Claude)
    for popup in tmux-dashboard tmux-daily tmux-claude-scratch; do
        if tmux -L "$socket" list-keys -T prefix 2> /dev/null | grep -q "$popup"; then
            ok "ポップアップのキーが割り当たっている ($popup)"
        else
            fail "ポップアップのキーが割り当たっている ($popup)"
        fi
    done
    tmux -L "$socket" kill-server 2> /dev/null || true
else
    skip "チートシートのキー割り当て" "tmux が無い"
fi

# --- bin のスモークテスト ---------------------------------------------------

check "pr-review --help が動く" "$DOTPATH/bin/pr-review" --help

# PR の worktree だと分からない場所を渡したら、黙って開かずエラーにする
if output=$("$DOTPATH/bin/pr-review" --dry-run "$DOTPATH" 2>&1); then
    fail "pr-review が PR 以外の場所で失敗する" "エラーにならなかった: $output"
else
    ok "pr-review が PR 以外の場所で失敗する"
fi

if have python3; then
    check "hunk-notes --help が動く" "$DOTPATH/bin/hunk-notes" --help

    # agent-context の注釈が、ライブ注釈の形 (行指定) に移ること。
    # ここがずれると注釈が別の行に付く / 黙って落ちる
    notes_json=$(mktemp "${TMPDIR:-/tmp}/dotfiles-test-notes.XXXXXX") || notes_json=""
    if [ -n "$notes_json" ]; then
        cat > "$notes_json" <<'JSON'
{"version": 1,
 "files": [{"path": "a.txt",
            "annotations": [{"newRange": [12, 20], "summary": "s", "rationale": "r"}]}]}
JSON
        output=$("$DOTPATH/bin/hunk-notes" "$notes_json" --dry-run 2>&1)
        if printf '%s' "$output" | grep -q '"newLine": 12' &&
            printf '%s' "$output" | grep -q '"filePath": "a.txt"'; then
            ok "hunk-notes が newRange を行指定に移す"
        else
            fail "hunk-notes が newRange を行指定に移す" "$output"
        fi

        # 位置の無い注釈は黙って捨てずにエラーにする
        cat > "$notes_json" <<'JSON'
{"files": [{"path": "a.txt", "annotations": [{"summary": "位置が無い"}]}]}
JSON
        if output=$("$DOTPATH/bin/hunk-notes" "$notes_json" --dry-run 2>&1); then
            fail "hunk-notes が位置の無い注釈で失敗する" "エラーにならなかった: $output"
        else
            ok "hunk-notes が位置の無い注釈で失敗する"
        fi
        rm -f "$notes_json"
    else
        skip "hunk-notes の変換" "一時ファイルを作れない"
    fi
else
    skip "hunk-notes のスモークテスト" "python3 が無い"
fi

# worktree フック (80-review)。source されるものなので、pr-review と
# __wt_interactive を差し替えて分岐だけを見る。窓は開かない
if have zsh; then
    review_hook="$DOTPATH/.zsh/worktree-hooks/80-review"
    review_hook_stub="
        __wt_interactive() { return 0 }
        pr-review() { print CALLED }
        source '$review_hook'
    "

    output=$(WT_SOURCE=pr WT_PR_NUMBER=77 WT_PATH="$DOTPATH" TMUX=fake \
        zsh -c "$review_hook_stub" 2>&1)
    if printf '%s' "$output" | grep -q CALLED; then
        ok "80-review が PR の worktree で pr-review を呼ぶ"
    else
        fail "80-review が PR の worktree で pr-review を呼ぶ" "$output"
    fi

    # stdout は wtadd --print-path のものなので、フックは汚してはいけない
    output=$(WT_SOURCE=pr WT_PR_NUMBER=77 WT_PATH="$DOTPATH" TMUX=fake \
        zsh -c "$review_hook_stub" 2> /dev/null)
    if [ -z "$output" ]; then
        ok "80-review が stdout を汚さない"
    else
        fail "80-review が stdout を汚さない" "$output"
    fi

    output=$(WT_SOURCE=branch WT_PR_NUMBER='' WT_PATH="$DOTPATH" TMUX=fake \
        zsh -c "$review_hook_stub" 2>&1)
    if printf '%s' "$output" | grep -q CALLED; then
        fail "80-review が PR 以外では何もしない" "$output"
    else
        ok "80-review が PR 以外では何もしない"
    fi

    output=$(env -u TMUX WT_SOURCE=pr WT_PR_NUMBER=77 WT_PATH="$DOTPATH" \
        zsh -c "$review_hook_stub" 2>&1)
    if printf '%s' "$output" | grep -q CALLED; then
        fail "80-review が tmux の外では何もしない" "$output"
    else
        ok "80-review が tmux の外では何もしない"
    fi
else
    skip "80-review フックの分岐" "zsh が無い"
fi

if have tmux; then
    check "tmux-workspace --help が動く" "$DOTPATH/bin/tmux-workspace" --help

    # --editor / --agent が渡せること (pr-review が hunk を差し込むのに使う)
    check "tmux-workspace が --editor を受ける" \
        sh -c "'$DOTPATH/bin/tmux-workspace' --help | grep -q -- --editor"
else
    skip "tmux-workspace --help" "tmux が無い"
fi

# ダッシュボードの設定の組み立て (wtfutil 本体は起動しない)。
# 目印の行が repositories.local の中身に置き換わることを見る
dash_repos=$(mktemp "${TMPDIR:-/tmp}/dotfiles-test-repos.XXXXXX") || dash_repos=""
dash_cache=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test-cache.XXXXXX") || dash_cache=""
if [ -n "$dash_repos" ] && [ -n "$dash_cache" ]; then
    # config.yml が使っているキーはすべて対応表に要る。ここが噛み合わないと
    # パネルが黙って空になるので、テスト側も config.yml からキーを拾って書き出す
    sed -n 's/^[[:space:]]*# __REPO:\([A-Za-z0-9_-]*\)__$/\1 = owner\/\1-example/p' \
        "$DOTPATH/.config/wtf/config.yml" > "$dash_repos"
    printf '# コメント行は無視される\n\n' >> "$dash_repos"
    output=$(
        WTF_CONFIG_SRC="$DOTPATH/.config/wtf/config.yml" \
            WTF_REPOSITORIES_FILE="$dash_repos" \
            XDG_CACHE_HOME="$dash_cache" \
            "$DOTPATH/bin/tmux-dashboard" --config < /dev/null 2>&1
    )
    # 目印の行 (行全体が # __REPO:キー__) が残っていないことを見る。
    # 冒頭の説明コメントにも同じ名前が出てくるので、素の grep では判定できない
    if [ -f "$output" ] &&
        grep -q -- "- owner/backend-example" "$output" &&
        ! grep -qE '^[[:space:]]*# __REPO:' "$output" &&
        ! grep -q "コメント行" "$output"; then
        ok "tmux-dashboard がリポジトリ名を設定に差し込む"
    else
        fail "tmux-dashboard がリポジトリ名を設定に差し込む" "$output"
    fi

    # 対応表が足りないときは、黙って空のパネルにせずエラーで止まること
    printf 'backend = owner/example\n' > "$dash_repos"
    if output=$(
        WTF_CONFIG_SRC="$DOTPATH/.config/wtf/config.yml" \
            WTF_REPOSITORIES_FILE="$dash_repos" \
            XDG_CACHE_HOME="$dash_cache" \
            "$DOTPATH/bin/tmux-dashboard" --config < /dev/null 2>&1
    ); then
        fail "対応表にキーが無ければ失敗する" "エラーにならなかった: $output"
    else
        ok "対応表にキーが無ければ失敗する"
    fi

    # 対応表そのものが無いときも同じ
    if output=$(
        WTF_CONFIG_SRC="$DOTPATH/.config/wtf/config.yml" \
            WTF_REPOSITORIES_FILE="$dash_cache/存在しない" \
            XDG_CACHE_HOME="$dash_cache" \
            "$DOTPATH/bin/tmux-dashboard" --config < /dev/null 2>&1
    ); then
        fail "対応表が無ければ失敗する" "エラーにならなかった: $output"
    else
        ok "対応表が無ければ失敗する"
    fi
    rm -f "$dash_repos"
    rm -rf "$dash_cache"
else
    skip "tmux-dashboard の設定の組み立て" "一時ファイルを作れない"
fi

# 予定の素のテキスト出力 (ダッシュボードのパネルが読む)。
# 入力を待つ実装に戻ったら気付けるよう、標準入力は閉じて呼ぶ
if [ "$(uname)" = "Darwin" ] && have icalBuddy && have python3; then
    if output=$("$DOTPATH/bin/tmux-status-popup" calendar --plain < /dev/null 2>&1); then
        ok "tmux-status-popup calendar --plain が待たずに終わる"
    else
        fail "tmux-status-popup calendar --plain が待たずに終わる" "$output"
    fi
else
    skip "tmux-status-popup calendar --plain" "macOS の icalBuddy が無い"
fi

# ダッシュボードのパネル (ステータスバーと同じデータを縦に開いて出す)。
# データが無い環境でも「取れていません」と出して 0 で終わる作りなので、出力があることを見る
if have python3; then
    for panel in claude network; do
        if output=$("$DOTPATH/bin/tmux-status-right" --panel "$panel" < /dev/null 2>&1) &&
            [ -n "$output" ]; then
            ok "tmux-status-right --panel $panel が出力を返す"
        else
            fail "tmux-status-right --panel $panel が出力を返す" "$output"
        fi
    done

    # 知らない名前を黙って通すと、パネルが空のまま気付けない
    if output=$("$DOTPATH/bin/tmux-status-right" --panel nope < /dev/null 2>&1); then
        fail "知らないパネル名でエラーになる" "エラーにならなかった: $output"
    else
        ok "知らないパネル名でエラーになる"
    fi

    # 設定が呼んでいるパネルが実装されていること (config.yml と実装のずれを見る)
    # パネル名は [a-z]* なので単語分割で回す。sed の結果を直接 for に渡すと
    # while read を勧める指摘 (SC2013) が出るが、パイプにすると集計が
    # サブシェルに閉じてしまうため、一度変数に受けてから回す
    configured_panels=$(
        sed -n 's/.*"--panel", "\([a-z]*\)".*/\1/p' "$DOTPATH/.config/wtf/config.yml"
    )
    missing=""
    for panel in $configured_panels; do
        "$DOTPATH/bin/tmux-status-right" --panel "$panel" > /dev/null 2>&1 < /dev/null ||
            missing="$missing $panel"
    done
    if [ -z "$missing" ]; then
        ok "config.yml が呼ぶパネルがすべて実装されている"
    else
        fail "config.yml が呼ぶパネルがすべて実装されている" "無いパネル:$missing"
    fi
else
    skip "ダッシュボードのパネル" "python3 が無い"
fi

# デイリーメモの選び方 (Glow は起動しない。どのファイルを開くかだけ見る)
daily_dir=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test-daily.XXXXXX") || daily_dir=""
if [ -n "$daily_dir" ]; then
    : > "$daily_dir/2026-01-02.md"
    : > "$daily_dir/2026-01-10.md"
    : > "$daily_dir/2025-12-31.md"

    # 当日のものが無ければ、更新時刻ではなく日付が一番新しいもの
    touch "$daily_dir/2025-12-31.md"
    output=$(KB_DAILY_DIR="$daily_dir" "$DOTPATH/bin/tmux-daily" --path < /dev/null 2>&1)
    if [ "$output" = "$daily_dir/2026-01-10.md" ]; then
        ok "当日が無ければ日付が一番新しいメモを開く"
    else
        fail "当日が無ければ日付が一番新しいメモを開く" "$output"
    fi

    # 当日のものがあればそれを開く
    today_file="$daily_dir/$(date +%Y-%m-%d).md"
    : > "$today_file"
    output=$(KB_DAILY_DIR="$daily_dir" "$DOTPATH/bin/tmux-daily" --path < /dev/null 2>&1)
    if [ "$output" = "$today_file" ]; then
        ok "当日のメモがあればそれを開く"
    else
        fail "当日のメモがあればそれを開く" "$output"
    fi

    # 置き場が無いときは黙って終わらずエラーにする
    if output=$(KB_DAILY_DIR="$daily_dir/存在しない" "$DOTPATH/bin/tmux-daily" --path \
        < /dev/null 2>&1); then
        fail "置き場が無ければ失敗する" "エラーにならなかった: $output"
    else
        ok "置き場が無ければ失敗する"
    fi

    rm -f "$daily_dir"/*.md
    rmdir "$daily_dir"
else
    skip "デイリーメモの選び方" "一時ディレクトリを作れない"
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
