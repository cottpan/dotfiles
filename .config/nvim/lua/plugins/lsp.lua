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
        virtual_text = { prefix = "●" },
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
      -- nvim-cmp の補完能力を全サーバに渡す
      local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
      if ok then
        vim.lsp.config("*", { capabilities = cmp_lsp.default_capabilities() })
      end

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
}
