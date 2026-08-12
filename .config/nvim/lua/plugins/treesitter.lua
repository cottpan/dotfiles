-- シンタックスハイライト / インデント (旧 syntax enable の強化版)
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master", -- main ブランチは API が別物なので固定する
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    main = "nvim-treesitter.configs",
    opts = function()
      local ensure_installed = {
        "bash",
        "c",
        "cpp",
        "diff",
        "dockerfile",
        "gitcommit",
        "go",
        "hcl",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "ruby",
        "rust",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      }

      -- swift のパーサは生成に tree-sitter CLI と node が要るので、揃っている環境だけ対象にする
      if vim.fn.executable("tree-sitter") == 1 and vim.fn.executable("node") == 1 then
        table.insert(ensure_installed, "swift")
      end

      return {
        ensure_installed = ensure_installed,
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
      }
    end,
  },
}
