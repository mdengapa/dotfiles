return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Buscar archivos" },
    { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Buscar texto (ripgrep)" },
    { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers abiertos" },
    { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Ayuda" },
    { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Archivos recientes" },
    { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnósticos" },
  },
  config = function()
    local telescope = require("telescope")
    telescope.setup({
      defaults = {
        mappings = {
          i = { ["<esc>"] = require("telescope.actions").close },
        },
      },
    })
    pcall(telescope.load_extension, "fzf")
  end,
}
