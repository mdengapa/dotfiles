-- IMPORTANTE: nvim-treesitter tuvo una reescritura incompatible en su rama
-- por defecto ("main"). Esta config usa la rama "master", que el propio
-- proyecto mantiene por compatibilidad hacia atrás con la API clásica
-- (nvim-treesitter.configs.setup). Si en algún momento quieres migrar a la
-- rama nueva, es un cambio de API completo, no solo quitar esta línea.
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    ensure_installed = {
      "bash", "lua", "vim", "vimdoc", "markdown", "markdown_inline",
      "python", "javascript", "typescript", "json", "yaml", "toml",
      "dockerfile", "sql", "gitignore",
    },
    highlight = { enable = true },
    indent = { enable = true },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
