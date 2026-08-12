-- 見た目まわり: 旧 vim-colors-solarized / vim-airline の置き換え
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
      extensions = { "lazy", "quickfix" },
    },
  },
}
