-- 見た目まわり: 旧 vim-colors-solarized / vim-airline の置き換えと、その周辺
return {
  {
    "maxmx03/solarized.nvim",
    lazy = false,
    priority = 1000, -- 他プラグインより先に読み込む
    opts = {
      transparent = { enabled = false },
    },
    config = function(_, opts)
      require("solarized").setup(opts)
      vim.cmd.colorscheme("solarized")
    end,
  },

  -- ファイルタイプのアイコン。lualine / neo-tree / dropbar などが共通で使う
  -- (Nerd Font が必要。dotfiles では font-symbols-only-nerd-font を入れている)
  { "nvim-tree/nvim-web-devicons", lazy = true },

  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "auto",
        globalstatus = true,
        section_separators = "",
        component_separators = "|",
      },
      sections = {
        -- 旧 airline_section_c = '%t' / _x = filetype / _z = 行:桁 + ale 件数 に相当
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff" },
        lualine_c = { { "filename", path = 0 } },
        lualine_x = { "diagnostics", "filetype" },
        lualine_y = {},
        lualine_z = { "location" },
      },
      extensions = { "lazy", "quickfix", "neo-tree" },
    },
  },

  -- 引数なしで起動したときのスタート画面
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      theme = "hyper",
      config = {
        week_header = { enable = true },
        shortcut = {
          { desc = "Files", group = "Label", action = "Telescope find_files", key = "f" },
          { desc = "Grep", group = "Label", action = "Telescope live_grep", key = "g" },
          { desc = "Tree", group = "Label", action = "Neotree toggle", key = "e" },
          { desc = "Lazy", group = "Label", action = "Lazy", key = "l" },
        },
        project = { enable = true, limit = 5 },
        mru = { limit = 8 },
        footer = {},
      },
    },
  },

  -- winbar にファイルパスとカーソル位置のシンボルを出す (クリックで移動できる)
  {
    "Bekaboo/dropbar.nvim",
    event = "BufReadPost",
    keys = {
      {
        "<leader>;",
        function()
          require("dropbar.api").pick()
        end,
        desc = "Pick from dropbar",
      },
    },
    opts = {},
  },

  -- インデントと、カーソルがいるチャンクの範囲を可視化する
  {
    "shellRaining/hlchunk.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      chunk = { enable = true },
      indent = { enable = true },
      line_num = { enable = false },
      blank = { enable = false },
    },
    config = function(_, opts)
      require("hlchunk").setup(opts)
    end,
  },
}
