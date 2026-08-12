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