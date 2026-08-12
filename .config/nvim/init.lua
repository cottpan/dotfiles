-- Neovim エントリポイント
-- 旧 .vimrc (dein.vim 構成) からの移行。プラグイン管理は lazy.nvim。

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("options")
require("keymaps")

-- lazy.nvim を無ければ取得する (dein の bootstrap 相当)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" } }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "solarized", "habamax" } },
  checker = { enabled = false },
  change_detection = { notify = false },
})
