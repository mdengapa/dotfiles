return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    current_line_blame = false,
    on_attach = function(bufnr)
      local gitsigns = require("gitsigns")
      local map = function(mode, l, r, desc)
        vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
      end
      map("n", "]c", gitsigns.next_hunk, "Siguiente cambio de git")
      map("n", "[c", gitsigns.prev_hunk, "Cambio de git anterior")
      map("n", "<leader>hs", gitsigns.stage_hunk, "Stage hunk")
      map("n", "<leader>hr", gitsigns.reset_hunk, "Reset hunk")
      map("n", "<leader>hp", gitsigns.preview_hunk, "Preview hunk")
      map("n", "<leader>hb", function() gitsigns.blame_line({ full = true }) end, "Blame de la línea")
    end,
  },
}
