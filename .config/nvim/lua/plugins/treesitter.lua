-- シンタックスハイライト / インデント (旧 syntax enable の強化版)
--
-- master ブランチは Neovim 0.12 の treesitter API と噛み合わず、markdown の
-- injection を解析するたびに get_node_text で落ちる。main ブランチを使う。
-- main はパーサの導入だけを担当し、ハイライトの有効化は vim.treesitter.start が行う。
return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup({})

      local parsers = {
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
        table.insert(parsers, "swift")
      end

      -- 未導入のものだけを非同期で入れる
      pcall(ts.install, parsers)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TreesitterStart", { clear = true }),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if not lang then
            return
          end
          -- パーサが無いファイルタイプでは何もしない
          if not pcall(vim.treesitter.start, args.buf, lang) then
            return
          end
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })
    end,
  },

  -- 画面外に出た関数やブロックの開始行を上部に固定表示する
  {
    "nvim-treesitter/nvim-treesitter-context",
    main = "treesitter-context", -- モジュール名がリポジトリ名と違う
    event = "BufReadPost",
    opts = {
      max_lines = 3,
      multiline_threshold = 1,
      separator = "─",
    },
  },
}
