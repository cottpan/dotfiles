-- 旧 .vimrc のキーマップ移植 + 診断まわり
local map = vim.keymap.set

-- 検索結果のハイライトを Esc 連打でクリアする
map("n", "<ESC><ESC>", "<Cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- 診断間の移動。旧 .vimrc では ale の <C-k>/<C-j> だったが、C-hjkl は
-- ウィンドウ移動 (tmux / harlequin と揃える) に譲り、[b / ]b と同じ括弧の作法に寄せた
local function jump_diagnostic(count)
  if vim.diagnostic.jump then -- Neovim 0.11+
    vim.diagnostic.jump({ count = count, float = true })
  elseif count < 0 then
    vim.diagnostic.goto_prev({ float = true })
  else
    vim.diagnostic.goto_next({ float = true })
  end
end

map("n", "[d", function()
  jump_diagnostic(-1)
end, { desc = "Previous diagnostic" })
map("n", "]d", function()
  jump_diagnostic(1)
end, { desc = "Next diagnostic" })
-- <leader>e はファイルツリー (neo-tree) に譲っている
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

-- ウィンドウ移動 (tmux の prefix h/j/k/l、harlequin の C-hjkl と同じ並び)
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- バッファ移動 (旧 airline tabline の代替操作)
map("n", "[b", "<Cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "]b", "<Cmd>bnext<CR>", { desc = "Next buffer" })
