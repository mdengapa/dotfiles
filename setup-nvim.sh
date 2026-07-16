#!/usr/bin/env bash
#
# setup-nvim.sh — Configuración completa de Neovim usando lazy.nvim.
#
# Incluye: LSP vía mason.nvim + mason-lspconfig + la API nativa de Neovim
# (vim.lsp.config / vim.lsp.enable, no la API vieja de nvim-lspconfig — ver nota
# más abajo), treesitter, telescope, blink.cmp (autocompletado), lualine,
# gitsigns, which-key y autopairs.
#
# Uso: bash setup-nvim.sh   (igual que setup.sh: local o vía curl con REPO_URL)
# Requiere haber corrido (o correr después) setup.sh para Homebrew/neovim/etc.
#
# ---------------------------------------------------------------------------
# NOTA IMPORTANTE SOBRE VIGENCIA (por qué esto no es el típico tutorial viejo):
#
# nvim-lspconfig dejó de tener API programable — su propio README dice que
# ahora es un repo "solo de datos" y que su API antigua (require('lspconfig')
# .server.setup{}) "no debe usarse externamente". Neovim 0.11+ trae la API
# nativa vim.lsp.config()/vim.lsp.enable(), y mason-lspconfig ya la usa por
# defecto (automatic_enable). Si ves tutoriales con .setup_handlers() o
# automatic_installation, son de antes de este cambio — no los mezcles con
# esto.
#
# También uso blink.cmp en vez de nvim-cmp: es el motor de autocompletado que
# ha desplazado a nvim-cmp en la mayoría de configs nuevas (más rápido, trae
# fuentes LSP/buffer/path/snippets integradas, menos plugins que gestionar).
# ---------------------------------------------------------------------------

set -euo pipefail

log()  { printf '\033[1;34m[setup-nvim]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[setup-nvim][aviso]\033[0m %s\n' "$*"; }

REPO_URL="https://github.com/mdengapa/dotfiles.git"
DEFAULT_REPO_DIR="$HOME/dotfiles"

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" 2>/dev/null && pwd || true)"

if [ -n "$SCRIPT_DIR" ] && git -C "$SCRIPT_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
else
  REPO_ROOT="$DEFAULT_REPO_DIR"
  if [ ! -d "$REPO_ROOT/.git" ]; then
    log "No estoy dentro de un repo git. Clonando dotfiles en $REPO_ROOT..."
    git clone "$REPO_URL" "$REPO_ROOT"
  fi
fi
log "Repo de dotfiles: $REPO_ROOT"

NVIM_DIR="$REPO_ROOT/.config/nvim"
mkdir -p "$NVIM_DIR/lua/config" "$NVIM_DIR/lua/plugins"

# ---------------------------------------------------------------------------
# Comprobaciones de dependencias — solo avisa, no instala nada por su cuenta
# (mismo criterio que en setup.sh: no te pisa gestores de versiones propios)
# ---------------------------------------------------------------------------
if ! command -v node >/dev/null 2>&1; then
  warn "No encuentro 'node'. pyright, ts_ls y bashls (vía Mason) lo necesitan. Instálalo con 'brew install node' o tu gestor habitual (nvm/fnm/mise)."
fi
if ! command -v cc >/dev/null 2>&1 && ! command -v gcc >/dev/null 2>&1 && ! command -v clang >/dev/null 2>&1; then
  warn "No encuentro un compilador de C. Treesitter y telescope-fzf-native lo necesitan (Xcode Command Line Tools en macOS: xcode-select --install)."
fi
if ! command -v rg >/dev/null 2>&1; then
  warn "ripgrep (rg) no está instalado — Telescope live_grep no funcionará. setup.sh debería haberlo instalado."
fi

write_if_missing() {
  if [ -f "$1" ]; then
    log "Ya existe, no lo toco: $1"
    return 1
  fi
  return 0
}

if write_if_missing "$NVIM_DIR/init.lua"; then
cat > "$NVIM_DIR/init.lua" <<'EOF'
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
EOF
fi

if write_if_missing "$NVIM_DIR/lua/config/options.lua"; then
cat > "$NVIM_DIR/lua/config/options.lua" <<'EOF'
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.breakindent = true
opt.undofile = true
opt.ignorecase = true
opt.smartcase = true
opt.signcolumn = "yes"
opt.updatetime = 250
opt.timeoutlen = 300
opt.splitright = true
opt.splitbelow = true
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.inccommand = "split"
opt.scrolloff = 8
opt.termguicolors = true
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.wrap = false
opt.cursorline = true

-- Comentarios (gc / gcc) son nativos desde Neovim 0.10, no hace falta plugin.

local state = vim.fn.stdpath("state")
opt.backupdir = state .. "/backup//"
opt.directory = state .. "/swap//"
opt.undodir = state .. "/undo//"
EOF
fi

if write_if_missing "$NVIM_DIR/lua/config/keymaps.lua"; then
cat > "$NVIM_DIR/lua/config/keymaps.lua" <<'EOF'
local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "Salir a modo normal" })
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Guardar" })
map("n", "<leader>q", "<cmd>q<cr>", { desc = "Cerrar ventana" })
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Quitar resaltado de búsqueda" })

map("n", "<C-h>", "<C-w>h", { desc = "Ventana izquierda" })
map("n", "<C-j>", "<C-w>j", { desc = "Ventana abajo" })
map("n", "<C-k>", "<C-w>k", { desc = "Ventana arriba" })
map("n", "<C-l>", "<C-w>l", { desc = "Ventana derecha" })

map("v", "<", "<gv", { desc = "Indentar izquierda (mantiene selección)" })
map("v", ">", ">gv", { desc = "Indentar derecha (mantiene selección)" })

map("n", "<leader>e", "<cmd>Ex<cr>", { desc = "Explorador de archivos (netrw)" })
EOF
fi

if write_if_missing "$NVIM_DIR/lua/config/autocmds.lua"; then
cat > "$NVIM_DIR/lua/config/autocmds.lua" <<'EOF'
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Resaltar texto al copiar",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "Volver a la última posición del cursor al abrir un archivo",
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
EOF
fi

if write_if_missing "$NVIM_DIR/lua/config/lazy.lua"; then
cat > "$NVIM_DIR/lua/config/lazy.lua" <<'EOF'
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup("plugins", {
  install = { colorscheme = { "catppuccin" } },
  checker = { enabled = true, notify = false },
  change_detection = { notify = false },
})
EOF
fi

if write_if_missing "$NVIM_DIR/lua/plugins/colorscheme.lua"; then
cat > "$NVIM_DIR/lua/plugins/colorscheme.lua" <<'EOF'
return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  opts = {
    flavour = "mocha",
    integrations = {
      telescope = true,
      gitsigns = true,
      which_key = true,
      mason = true,
      native_lsp = { enabled = true },
    },
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
EOF
fi

if write_if_missing "$NVIM_DIR/lua/plugins/treesitter.lua"; then
cat > "$NVIM_DIR/lua/plugins/treesitter.lua" <<'EOF'
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
EOF
fi

if write_if_missing "$NVIM_DIR/lua/plugins/telescope.lua"; then
cat > "$NVIM_DIR/lua/plugins/telescope.lua" <<'EOF'
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
EOF
fi

if write_if_missing "$NVIM_DIR/lua/plugins/completion.lua"; then
cat > "$NVIM_DIR/lua/plugins/completion.lua" <<'EOF'
return {
  "saghen/blink.cmp",
  version = "1.*",
  dependencies = { "rafamadriz/friendly-snippets" },
  event = "InsertEnter",
  opts = {
    keymap = { preset = "default" },
    appearance = { nerd_font_variant = "mono" },
    completion = { documentation = { auto_show = true } },
    sources = { default = { "lsp", "path", "snippets", "buffer" } },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
EOF
fi

if write_if_missing "$NVIM_DIR/lua/plugins/lsp.lua"; then
cat > "$NVIM_DIR/lua/plugins/lsp.lua" <<'EOF'
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
EOF
fi

if write_if_missing "$NVIM_DIR/lua/plugins/statusline.lua"; then
cat > "$NVIM_DIR/lua/plugins/statusline.lua" <<'EOF'
return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "catppuccin",
      globalstatus = true,
    },
  },
}
EOF
fi

if write_if_missing "$NVIM_DIR/lua/plugins/gitsigns.lua"; then
cat > "$NVIM_DIR/lua/plugins/gitsigns.lua" <<'EOF'
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
EOF
fi

if write_if_missing "$NVIM_DIR/lua/plugins/ui.lua"; then
cat > "$NVIM_DIR/lua/plugins/ui.lua" <<'EOF'
return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
}
EOF
fi

# ---------------------------------------------------------------------------
# Symlink (por si este script se corre sin haber corrido setup.sh antes)
# ---------------------------------------------------------------------------
if [ ! -L "$HOME/.config/nvim" ]; then
  if [ -e "$HOME/.config/nvim" ]; then
    BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    mv "$HOME/.config/nvim" "$BACKUP_DIR/nvim"
    warn "Backup: ~/.config/nvim -> $BACKUP_DIR/nvim"
  fi
  mkdir -p "$HOME/.config"
  ln -sf "$NVIM_DIR" "$HOME/.config/nvim"
  log "Enlazado: ~/.config/nvim -> $NVIM_DIR"
fi

log "Configuración de Neovim lista en: $NVIM_DIR"
log "Abre nvim: la primera vez, lazy.nvim clona todos los plugins solo."
log "Dentro de nvim corre :Mason para ver/instalar servidores LSP manualmente si hace falta."
if [ -n "$(git -C "$REPO_ROOT" status --porcelain -- .config/nvim 2>/dev/null)" ]; then
  warn "Hay cambios sin commitear en .config/nvim. Revisa y haz commit: cd $REPO_ROOT && git status"
fi
