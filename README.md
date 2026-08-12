## Installation

### macOS / Fedora
```bash
bash -c "$(curl -fsSL https://bit.ly/3X8YDzE)"
```

Fedora では `sudo` 権限が必要です（`dnf` でパッケージをインストールします）。
インストール後、ログインシェルを zsh に変更してください。

```bash
chsh -s "$(command -v zsh)"
```

### Neovim

エディタは Neovim (`.config/nvim`) を使います。プラグイン管理は
[lazy.nvim](https://github.com/folke/lazy.nvim) で、初回起動時に自動で bootstrap されます。
LSP サーバは mason 経由で導入されるため、初回起動後 `:Mason` / `:checkhealth` で状態を確認できます。

`.vimrc` は sudo 時など vim しか無い環境向けに、プラグイン非依存の最小設定だけを残しています。

## Test

```bash
make test           # 全部
make test-syntax    # 構文チェック (副作用なし)
make test-deploy    # 使い捨ての HOME に配って結果を確認する
make test-runtime   # このマシンで実際に動くかを見る
```

| スイート | 見るもの |
| --- | --- |
| `syntax` | sh / bash / zsh / Python / Lua の構文、tmux 設定の読み込み、TOML、shellcheck |
| `deploy` | `make install` が張るシンボリックリンク、除外対象、二重実行、`make clean` |
| `runtime` | PATH、`bin/` の実行権限、必要なコマンドの有無、zsh / Neovim / tmux が実際に起動するか |

道具が入っていない環境では該当項目を skip するので、どの環境でも走ります。
`deploy` は `HOME` を一時ディレクトリに差し替えて実行するため、実際のホームディレクトリには触れません。

CI では macOS と Fedora コンテナの両方で `syntax` と `deploy` を回し、
macOS では加えて `install.sh` を最初から流したうえで `runtime` を確認しています。