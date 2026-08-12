-- 旧 .vimrc の set 系設定を移植したもの
local opt = vim.opt

-- 表示
opt.number = true -- 行番号を表示する
opt.showmatch = true -- 閉括弧が入力された時、対応する括弧を強調する
opt.termguicolors = true -- true color (solarized の色を正しく出すため)
opt.background = "dark"
opt.signcolumn = "yes" -- 診断表示で画面が横にずれないようにする
opt.list = true -- エスケープシーケンスの表示 tab eol
opt.listchars = { tab = "▸·", eol = "¬" }

-- インデント
opt.autoindent = true -- 新しい行のインデントを現在行と同じにする
opt.smartindent = true
opt.smarttab = true -- 新しい行を作った時に高度な自動インデントを行う
opt.expandtab = true -- タブの代わりに空白文字を挿入する
opt.tabstop = 4 -- タブ幅の設定
opt.shiftwidth = 4

-- 検索
opt.incsearch = true -- インクリメンタルサーチを行う
opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true -- 大文字を含む検索のときだけ大文字小文字を区別する

-- ファイル
opt.hidden = true -- 変更中のファイルでも、保存しないで他のファイルを表示する
opt.undofile = true -- undo 履歴を永続化する (backup/swap は Neovim 既定の state ディレクトリを使う)

-- grep: ripgrep があればそちらを使う (無ければ従来の grep 設定)
if vim.fn.executable("rg") == 1 then
  opt.grepprg = "rg --vimgrep --smart-case"
  opt.grepformat = "%f:%l:%c:%m"
else
  opt.grepprg = "grep -nh"
  opt.grepformat = "%f:%l:%m,%f:%l%m,%f  %l%m,%f"
end

-- vimgrep や grep した際に quickfix ウィンドウを開く
vim.api.nvim_create_autocmd("QuickFixCmdPost", {
  group = vim.api.nvim_create_augroup("QuickfixAutoOpen", { clear = true }),
  pattern = "*grep*",
  command = "cwindow",
})

-- 全角スペースの表示
local zenkaku = vim.api.nvim_create_augroup("ZenkakuSpace", { clear = true })
local function highlight_zenkaku_space()
  vim.cmd([[highlight ZenkakuSpace cterm=reverse ctermfg=DarkGray gui=reverse guifg=DarkGray]])
end
vim.api.nvim_create_autocmd("ColorScheme", {
  group = zenkaku,
  pattern = "*",
  callback = highlight_zenkaku_space,
})
vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter" }, {
  group = zenkaku,
  pattern = "*",
  command = [[match ZenkakuSpace /　/]],
})
highlight_zenkaku_space()

-- ヤンクした範囲をハイライトする
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
  callback = function()
    local hl = vim.hl or vim.highlight -- vim.highlight は 0.11 で vim.hl に改名
    hl.on_yank()
  end,
})
