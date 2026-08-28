-- 補完・スニペット・ファイル検索
-- 旧 Shougo/neosnippet(+snippets) は LuaSnip + friendly-snippets、
-- 旧 Shougo/vimshell はターミナル (:terminal) と telescope に置き換え
return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<Cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fg", "<Cmd>Telescope live_grep<CR>", desc = "Live grep" },
      { "<leader>fb", "<Cmd>Telescope buffers<CR>", desc = "Buffers" },
      { "<leader>fh", "<Cmd>Telescope help_tags<CR>", desc = "Help tags" },
      { "<leader>fd", "<Cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
    },
    opts = {},
  },

  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      {
        "L3MON4D3/LuaSnip",
        version = "v2.*",
        dependencies = { "rafamadriz/friendly-snippets" },
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
        end,
      },
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          -- 旧 neosnippet の <C-k> 展開に相当 (挿入モード時のみ)
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_locally_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.locally_jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- ファイルツリー
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<Cmd>Neotree toggle<CR>", desc = "File tree" },
      { "<leader>o", "<Cmd>Neotree focus<CR>", desc = "Focus file tree" },
    },
    opts = {
      window = {
        width = 32,
        mappings = {
          -- 組み込みの y は「ファイルをコピー」なので、パスのコピーは別キーに割り当てる
          ["Y"] = "copy_relative_path",
          ["gy"] = "copy_absolute_path",
        },
      },
      commands = {
        copy_relative_path = function(state)
          local node = state.tree:get_node()
          if not node then
            return
          end
          local path = node:get_id()
          -- cwd の外を指しているときは相対化できないので絶対パスのまま渡す
          local rel = vim.fs.relpath(vim.uv.cwd(), path) or path
          vim.fn.setreg("+", rel)
          vim.notify("Copied: " .. rel)
        end,
        copy_absolute_path = function(state)
          local node = state.tree:get_node()
          if not node then
            return
          end
          local path = node:get_id()
          vim.fn.setreg("+", path)
          vim.notify("Copied: " .. path)
        end,
      },
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        -- dotfiles リポジトリは .gitignore のホワイトリスト運用なので、
        -- 無視されているファイルも見えないと不便
        filtered_items = { hide_dotfiles = false, hide_gitignored = false },
      },
    },
  },

  -- j / k を連打したときだけ加速する
  {
    "rainbowhxch/accelerated-jk.nvim",
    keys = {
      { "j", "<Plug>(accelerated_jk_gj)", mode = "n", desc = "Down (accelerated)" },
      { "k", "<Plug>(accelerated_jk_gk)", mode = "n", desc = "Up (accelerated)" },
    },
    opts = {},
  },

  -- Markdown をバッファ内で整形して表示する。
  --
  -- 既定は見出し 1〜6 をそれぞれ別色の「背景ブロック」で描く
  -- (MarkviewHeading{N} -> MarkviewPalette{N} = Normal の bg に見出し色を 25% 混ぜた帯)。
  -- solarized dark だと帯が濁って本文より読みにくいので、glow (charmbracelet) の
  -- dark スタイル相当まで装飾量を落とす:
  --   h1 だけ帯、h2〜h5 は `##` を残した青の太字、h6 は緑・太字なし。
  {
    "OXY2DEV/markview.nvim",
    ft = { "markdown", "quarto", "rmd", "codecompanion" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- markview の MarkviewHeading* は ColorScheme のたびに MarkviewPalette* へ
      -- 貼り替えられ、opts.highlight_groups は現行 commit では配線されていないので、
      -- 衝突しない独自名のグループを自前で張る (`:colorscheme` で消えるため再作成も自分で)。
      local function heading_hl()
        local set = vim.api.nvim_set_hl
        -- glow の dark スタイルを solarized のパレットに置き換えたもの
        set(0, "MdHeading1", { fg = "#fdf6e3", bg = "#6c71c4", bold = true }) -- base3 on violet
        set(0, "MdHeading2", { fg = "#268bd2", bold = true }) -- blue
        set(0, "MdHeading3", { fg = "#268bd2", bold = true })
        set(0, "MdHeading4", { fg = "#268bd2", bold = true })
        set(0, "MdHeading5", { fg = "#268bd2", bold = true })
        set(0, "MdHeading6", { fg = "#859900" }) -- green (glow に合わせて太字なし)
        -- setext (`===` 下線) 見出し用。simple スタイルは line_hl_group で行全体を塗るので、
        -- h1 の帯をそのまま使うと画面端まで violet になる。色だけ借りる。
        set(0, "MdHeadingSetext1", { fg = "#6c71c4", bold = true })
      end

      heading_hl()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("MarkviewHeadingHl", { clear = true }),
        callback = heading_hl,
      })

      require("markview").setup({
        markdown = {
          headings = {
            shift_width = 0, -- 見出しをレベル分インデントしない

            -- h1 は `#` を隠して前後に空白を足した帯にする (glow の h1 相当)
            heading_1 = {
              style = "label",
              sign = false,
              padding_left = " ",
              padding_right = " ",
              icon = "",
              hl = "MdHeading1",
            },

            -- h2 以降は記号を残したまま行に色を乗せるだけ
            heading_2 = { style = "simple", sign = false, hl = "MdHeading2" },
            heading_3 = { style = "simple", hl = "MdHeading3" },
            heading_4 = { style = "simple", hl = "MdHeading4" },
            heading_5 = { style = "simple", hl = "MdHeading5" },
            heading_6 = { style = "simple", hl = "MdHeading6" },

            setext_1 = { style = "simple", sign = false, hl = "MdHeadingSetext1" },
            setext_2 = { style = "simple", sign = false, hl = "MdHeading2" },
          },

          -- 箇条書きの記号を glow と同じ中黒に揃える (既定は ● / ◈ / ◇ で階層ごとに別記号)
          list_items = {
            marker_minus = { text = "•" },
            marker_plus = { text = "•" },
            marker_star = { text = "•" },
          },

          -- 引用は太いブロックではなく細い縦線
          block_quotes = {
            default = { border = "│" },
          },

          -- `---` は既定だと虹色グラデーション + 中央にアイコンなので、ただの罫線にする。
          -- 既定の parts は 3 要素で、tbl_deep_extend が index ごとに混ぜてしまうため、
          -- 2/3 番目も明示的に無効化する。
          horizontal_rules = {
            parts = {
              {
                type = "repeating",
                direction = "left",
                repeat_amount = function()
                  return vim.o.columns
                end,
                text = "─",
                hl = "Comment",
              },
              { type = "text", text = "", hl = "Comment" },
              {
                type = "repeating",
                direction = "right",
                repeat_amount = function()
                  return 0
                end,
                text = "─",
                hl = "Comment",
              },
            },
          },

          -- テーブルは 1 本線の罫線 (既定は太さの違う複合罫線)
          tables = require("markview.presets").tables.single,
        },
      })
    end,
  },
}
