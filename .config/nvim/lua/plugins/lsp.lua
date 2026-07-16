return {
  { "mason-org/mason.nvim", opts = {} },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = {
        "lua_ls", "bashls", "pyright", "ts_ls", "jsonls", "yamlls", "dockerls",
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "saghen/blink.cmp" },
    config = function()
      -- Capacidades extendidas por blink.cmp para todos los servidores.
      -- "*" son los valores por defecto que vim.lsp.config aplica a
      -- cualquier servidor habilitado después (API nativa desde Neovim 0.11).
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      -- Override de ejemplo para lua_ls (evita el warning de "undefined global vim")
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
          },
        },
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "Keymaps de LSP al adjuntar un servidor",
        callback = function(event)
          local map = function(keys, func, desc)
            vim.keymap.set("n", keys, func, { buffer = event.buf, desc = desc })
          end
          map("gd", vim.lsp.buf.definition, "Ir a definición")
          map("gr", vim.lsp.buf.references, "Ver referencias")
          map("gI", vim.lsp.buf.implementation, "Ir a implementación")
          map("K", vim.lsp.buf.hover, "Documentación (hover)")
          map("<leader>rn", vim.lsp.buf.rename, "Renombrar símbolo")
          map("<leader>ca", vim.lsp.buf.code_action, "Acción de código")
          map("<leader>d", vim.diagnostic.open_float, "Ver diagnóstico")
          map("[d", vim.diagnostic.goto_prev, "Diagnóstico anterior")
          map("]d", vim.diagnostic.goto_next, "Diagnóstico siguiente")
        end,
      })
    end,
  },
}
