-- LSP: 旧 w0rp/ale (lint) と justmao945/vim-clang の置き換え
-- サーバの追加は :Mason の UI からでも、下の ensure_installed に足してもよい
return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      {
        "mason-org/mason-lspconfig.nvim",
        dependencies = { { "mason-org/mason.nvim", opts = {} } },
        opts = {
          ensure_installed = {
            "lua_ls",
            "clangd", -- 旧 vim-clang 相当
          },
        },
      },
      "hrsh7th/cmp-nvim-lsp",
    },
    init = function()
      -- 旧 ale の表示設定に相当する診断まわり
      vim.diagnostic.config({
        -- 行内の表示は tiny-inline-diagnostic に任せるので、標準の virtual_text は切る
        virtual_text = false,
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
          },
        },
        float = { border = "rounded", source = true },
      })

      -- lua_ls では Neovim 設定を書くので vim をグローバルとして認識させる
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            workspace = { checkThirdParty = false },
          },
        },
      })
    end,
    config = function()
      -- nvim-cmp の補完能力と、nvim-ufo が使う折りたたみ範囲を全サーバに渡す
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        capabilities = vim.tbl_deep_extend("force", capabilities, cmp_lsp.default_capabilities())
      end
      capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
      }
      vim.lsp.config("*", { capabilities = capabilities })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("LspKeymaps", { clear = true }),
        callback = function(args)
          local function map(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
          end
          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gr", vim.lsp.buf.references, "References")
          map("gi", vim.lsp.buf.implementation, "Go to implementation")
          map("K", vim.lsp.buf.hover, "Hover")
          map("<leader>rn", vim.lsp.buf.rename, "Rename")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
          map("<leader>f", function()
            vim.lsp.buf.format({ async = true })
          end, "Format buffer")
        end,
      })
    end,
  },

  -- 定義・参照などをプレビュー付きの一覧で開く
  -- (gd / gr の飛ぶだけの動きは残してあるので、見比べたい時にこちらを使う)
  {
    "dnlhc/glance.nvim",
    cmd = "Glance",
    keys = {
      { "<leader>gd", "<Cmd>Glance definitions<CR>", desc = "Glance definitions" },
      { "<leader>gr", "<Cmd>Glance references<CR>", desc = "Glance references" },
      { "<leader>gi", "<Cmd>Glance implementations<CR>", desc = "Glance implementations" },
      { "<leader>gy", "<Cmd>Glance type_definitions<CR>", desc = "Glance type definitions" },
    },
    opts = {},
  },

  -- バッファ内のシンボルを絞り込んで移動する
  {
    "bassamsdata/namu.nvim",
    cmd = "Namu",
    keys = {
      { "<leader>ss", "<Cmd>Namu symbols<CR>", desc = "Symbols in buffer" },
      { "<leader>sw", "<Cmd>Namu workspace<CR>", desc = "Symbols in workspace" },
    },
    config = function()
      require("namu").setup({
        namu_symbols = { enable = true, options = {} },
      })
    end,
  },

  -- 診断をカーソル行にコンパクトに出す (標準の virtual_text は上で切ってある)
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LspAttach",
    priority = 1000,
    config = function()
      require("tiny-inline-diagnostic").setup({
        preset = "modern",
        options = { show_source = { enabled = true } },
      })
    end,
  },

  -- LSP の情報を使った折りたたみ
  {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "BufReadPost",
    init = function()
      -- ufo は「最初は全部開いている」状態を前提にしている
      vim.o.foldcolumn = "1"
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
    keys = {
      {
        "zR",
        function()
          require("ufo").openAllFolds()
        end,
        desc = "Open all folds",
      },
      {
        "zM",
        function()
          require("ufo").closeAllFolds()
        end,
        desc = "Close all folds",
      },
    },
    opts = {
      -- LSP が折りたたみ範囲を返さない時はインデントで代用する
      provider_selector = function()
        return { "lsp", "indent" }
      end,
    },
  },
}
