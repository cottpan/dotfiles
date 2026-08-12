-- 旧 .vimrc のキーマップ移植 + 診断まわり
local map = vim.keymap.set

-- 検索結果のハイライトを Esc 連打でクリアする
map("n", "<ESC><ESC>", "<Cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- 旧: ale の <C-k>/<C-j> による指摘間の移動を LSP 診断へ置き換え
local function jump_diagnostic(count)
  if vim.diagnostic.jump then -- Neovim 0.11+
    vim.diagnostic.jump({ count = count, float = true })
  elseif count < 0 then
    vim.diagnostic.goto_prev({ float = true })
  else
    vim.diagnostic.goto_next({ float = true })
  end
end

map("n", "<C-k>", function()
  jump_diagnostic(-1)
end, { desc = "Previous diagnostic" })
map("n", "<C-j>", function()
  jump_diagnostic(1)
end, { desc = "Next diagnostic" })
-- <leader>e はファイルツリー (neo-tree) に譲っている
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Show diagnostic" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics to loclist" })

-- ウィンドウ移動
map("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- バッファ移動 (旧 airline tabline の代替操作)
map("n", "[b", "<Cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "]b", "<Cmd>bnext<CR>", { desc = "Next buffer" })
