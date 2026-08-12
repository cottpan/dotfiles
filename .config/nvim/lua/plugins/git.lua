-- git の差分表示と、行単位のコミット情報
return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- カーソル行の右端に「誰が・いつ・どのコミットで」を薄く出す
      current_line_blame = true,
      current_line_blame_opts = {
        virt_text_pos = "eol",
        delay = 300,
        ignore_whitespace = false,
      },
      current_line_blame_formatter = "  <author>, <author_time:%Y-%m-%d> · <summary>",
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        -- hunk 間の移動 (diff モード中は本来の ]c / [c を残す)
        map("n", "]c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Next hunk")
        map("n", "[c", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Previous hunk")

        map("n", "<leader>hs", gs.stage_hunk, "Stage hunk")
        map("n", "<leader>hr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>hp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>hd", gs.diffthis, "Diff this file")

        -- 行のコミットを詳しく見る / 行 blame の表示を切り替える
        map("n", "<leader>hb", function()
          gs.blame_line({ full = true })
        end, "Blame line (full)")
        map("n", "<leader>tb", gs.toggle_current_line_blame, "Toggle line blame")
      end,
    },
  },
}
