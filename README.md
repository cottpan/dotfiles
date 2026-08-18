## Installation

### macOS / Fedora / Ubuntu
```bash
bash -c "$(curl -fsSL https://bit.ly/3X8YDzE)"
```

Linux では `sudo` 権限が必要です（Fedora は `dnf`、Ubuntu は `apt` でパッケージを
インストールします）。Ubuntu は Debian 系の派生（Linux Mint など）も同じ経路で入ります。

Ubuntu の apt に入っている Neovim はプラグインの要求（0.11 以降）より古いことが
多いため、足りない場合は公式ビルドを `~/.local/nvim` に展開して `~/.local/bin/nvim`
から参照します。`gh` は標準リポジトリに無いので、GitHub 公式の apt リポジトリを追加します。

Python の [uv](https://docs.astral.sh/uv/) は、macOS では Brewfile 経由で、Linux では
公式のインストーラで `~/.local/bin` に入れます（シェルの設定は書き換えず、`.zshenv` が
通している PATH に任せます）。

### mise で入れる CLI

`.config/mise/config.toml` の `[tools]` に書いたものは、`make deploy`（`etc/init/install.sh`）が
`mise install` で入れます。macOS / Linux のどちらにも同じ版が入るので、brew と dnf / apt で
出来が違うもの・そもそも無いものはここに置きます。PATH は `.zshrc` の `mise activate` が通します。

| ツール | 用途 |
| --- | --- |
| [hunk](https://hunk.dev/) | レビュー向けのターミナル diff ビューア（`hunk diff` / `hunk show`） |
| [jnv](https://github.com/ynqa/jnv) | jq の対話版。クエリを打ちながら結果を見る |
| [lazydocker](https://github.com/jesseduffield/lazydocker) | コンテナ / ログ / リソースの TUI |
| [yazi](https://yazi-rs.github.io/) | ファイラ。`ya` も一緒に入る |

`btop` は aqua が Linux のバイナリしか持っていないので、mise ではなく Brewfile と
各ディストロのパッケージで入れます。

PR / issue のダッシュボード [gh-dash](https://github.com/dlvhdr/gh-dash) は gh の拡張として
入れます（`gh dash` で起動）。未ログインの環境では入らないことがあるので、その場合は
`gh auth login` のあとに `gh extension install dlvhdr/gh-dash` を実行してください。

### DB クライアント

ターミナルの SQL クライアントとして [harlequin](https://harlequin.sh/) を、公式が勧める
`uv tool install` で入れます（`etc/init/install.sh` の `HARLEQUIN_PACKAGE`）。既定は
PostgreSQL のアダプタ入り (`harlequin[postgres]`) で、DuckDB / SQLite は本体に入っています。
他のアダプタが要るときは extras を足して入れ直します。

```bash
uv tool install --force 'harlequin[postgres,mysql,s3]'
```

インストール後、ログインシェルを zsh に変更してください。

```bash
chsh -s "$(command -v zsh)"
```

### Neovim

エディタは Neovim (`.config/nvim`) を使います。プラグイン管理は
[lazy.nvim](https://github.com/folke/lazy.nvim) で、初回起動時に自動で bootstrap されます。
LSP サーバは mason 経由で導入されるため、初回起動後 `:Mason` / `:checkhealth` で状態を確認できます。

`.vimrc` は sudo 時など vim しか無い環境向けに、プラグイン非依存の最小設定だけを残しています。

## キー操作の約束

道具が増えるほど操作を覚えられなくなるので、**毎回使う 4 つだけ**を揃えます。
それ以外は各ツールの既定のままにして、覚えるのは諦めます。

| | キー |
| --- | --- |
| 移動 | `j` / `k` |
| 閉じる | `q` |
| 検索 | `/` |
| ヘルプ | `?` |

| ツール | 状態 |
| --- | --- |
| Neovim / tmux | 基準（tmux は prefix `C-q` のあと。`C-q ?` でチートシート） |
| hunk | 既定で 4 つとも揃っている（`g` / `G`、`[` `]` でハンク移動も vim 風） |
| yazi / gh-dash / glow | 既定で揃っている（yazi のヘルプだけ `?` を足した） |
| btop | `vim_keys = true` を入れて移動を `j` / `k` に |
| harlequin | **移動だけ**（結果の表と左のツリー）。理由は下記 |

新しい道具を足すときは、この 4 つが合っているかだけ見て、合わなければ設定で寄せます。

### 揃えられないもの

**harlequin** は SQL を打ち込むアプリなので、アプリ全体に効く `quit` / `help` / `find` を
素の `q` / `?` / `/` に置くと、エディタでその文字が打てなくなります。ペインにフォーカスが
あるときだけ効く `results_viewer.*` / `data_catalog.*` だけを vim に寄せ、終了は `C-t` の
ままにしています（`C-q` は tmux の prefix に吸われるため）。

**btop** は検索が無く、ヘルプは `h` です。移動と終了だけ合わせています。

### 設定ファイルの置き場

btop は終了のたびに設定ファイルを丸ごと書き戻すので、リポジトリから symlink すると
起動しただけで差分が出ます。`etc/init/install.sh` が `vim_keys` の値だけを流し込みます。
hunk は設定 (`.config/hunk/config.toml`) を持ち歩き、実行中に書く `state.json` は
`.gitignore` で外しています。

## PR レビュー

PR ごとに worktree を作り、[hunk](https://hunk.dev/) の diff にエージェントの解説を
付けながら読むための道具立てです。

```bash
fprwtree                 # PR を fzf で選んで worktree を作る (既存の zsh 関数)
pr-review                # その worktree をレビュー用ウィンドウで開く
```

`pr-review` はレビュー専用の tmux ウィンドウを作ります（`tmux-workspace --editor` で
エディタのペインを hunk に差し替えたもの）。

```
┌────────────────────┬──────────┐
│ hunk diff          │ claude   │
├────────────────────┤          │
│ terminal           │          │
└────────────────────┴──────────┘
```

worktree のパス (`<親>/<リポジトリ>.worktree/pr-<番号>-<ブランチ>`) から PR 番号を拾い、
マージ先は `gh pr view` で引いて `origin/<base>...HEAD` を開きます。`fprwtree` が
`wtadd` に渡す `--base` は PR の head なので、そこは当てになりません。

### 注釈は JSON を正とする

hunk の注釈にはライブ (`hunk session comment apply`) とファイル (`--agent-context`) の
二通りの入り口があり、ライブはセッションを閉じると消えます。そこで置き場を決めておき、
エージェントにはそこへ書かせます。

```
${XDG_STATE_HOME:-~/.local/state}/hunk-review/<リポジトリ>/pr-<番号>.json
```

`pr-review` はこれがあれば `--agent-context` で読み込むので、次に開いたときも解説が出ます
（worktree を消しても残ります）。開いている最中に反映したいときは `hunk-notes` を使います。

```bash
pr-review --print-notes                     # 置き場を出す (エージェントに渡す)
hunk-notes <notes.json> --replace --focus   # JSON を今開いている hunk に流し込む
```

同じ worktree に対して `pr-review` を二度呼んでも窓は増えず、開いている hunk の中身を
差し替えます（同一リポジトリに hunk が 2 つあると `--repo` の指定が曖昧になるため）。

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

CI では macOS と Fedora / Ubuntu コンテナで `syntax` と `deploy` を回し、
macOS では加えて `install.sh` を最初から流したうえで `runtime` を確認しています。