# make install / make clean を隔離した HOME で試す。
#
# 本物の HOME には触らない。Makefile が $(HOME) を使っているので上書きするだけで隔離できる。

suite "デプロイ (隔離した HOME)"

fake_home=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-test-home.XXXXXX") || {
    fail "一時 HOME の作成"
    return 0 2> /dev/null || true
}

deploy_cleanup() {
    [ -n "$fake_home" ] && rm -rf "$fake_home"
}

if output=$(cd "$DOTPATH" && HOME="$fake_home" make install 2>&1); then
    ok "make install が成功する"
else
    fail "make install が成功する" "$output"
fi

# ホームに置かれるべきもの
for name in .zshrc .zshenv .zprofile .tmux.conf .vimrc .dircolors .fzf.zsh bin .zsh; do
    if [ -e "$DOTPATH/$name" ]; then
        assert_symlink_to "$name がリポジトリを指す" "$fake_home/$name" "$DOTPATH/$name"
    fi
done

# .config 配下はディレクトリ単位でリンクされる
for dir in "$DOTPATH"/.config/*/; do
    name=$(basename "$dir")
    assert_symlink_to ".config/$name がリポジトリを指す" \
        "$fake_home/.config/$name" "$DOTPATH/.config/$name"
done

# .config 自体は実ディレクトリのまま (リポジトリを丸ごと張らない)
if [ -d "$fake_home/.config" ] && [ ! -L "$fake_home/.config" ]; then
    ok ".config は実ディレクトリのまま"
else
    fail ".config は実ディレクトリのまま" "$(ls -ld "$fake_home/.config" 2>&1)"
fi

# 配ってはいけないもの
for name in .git .github .gitignore .gitmodules .DS_Store; do
    assert_missing "$name は配らない" "$fake_home/$name"
done

# 2 回目を流しても壊れない (ln -sfn なので上書きされるだけ)
if output=$(cd "$DOTPATH" && HOME="$fake_home" make install 2>&1); then
    ok "make install を 2 回流しても成功する"
    assert_symlink_to "2 回目の後も .zshrc が正しい" "$fake_home/.zshrc" "$DOTPATH/.zshrc"
else
    fail "make install を 2 回流しても成功する" "$output"
fi

# リンク経由で中身が読める (壊れたリンクになっていない)
if [ -r "$fake_home/.config/nvim/init.lua" ]; then
    ok "リンク越しに .config/nvim/init.lua が読める"
else
    fail "リンク越しに .config/nvim/init.lua が読める" "壊れたリンクの可能性"
fi

# make clean で片付く
if output=$(cd "$DOTPATH" && HOME="$fake_home" make clean 2>&1); then
    ok "make clean が成功する"
else
    fail "make clean が成功する" "$output"
fi
assert_missing "clean 後に .zshrc が消えている" "$fake_home/.zshrc"
assert_missing "clean 後に bin が消えている" "$fake_home/bin"
assert_missing "clean 後に .config/nvim が消えている" "$fake_home/.config/nvim"

# make list が一覧を出す (Makefile の変数展開が壊れていないか)
if output=$(cd "$DOTPATH" && make list 2>&1) && [ -n "$output" ]; then
    case $output in
        *.zshrc*) ok "make list に .zshrc が出る" ;;
        *) fail "make list に .zshrc が出る" "$output" ;;
    esac
    case $output in
        *nvim*) ok "make list に .config/nvim が出る" ;;
        *) fail "make list に .config/nvim が出る" "$output" ;;
    esac
else
    fail "make list が動く" "$output"
fi

deploy_cleanup
