# dotfiles

Configuración de zsh, tmux y Neovim para macOS. El repo es la fuente de
verdad: los scripts instalan dependencias y enlazan esta configuración a
`~/.config`, pero no la regeneran una vez que ya existe.

## Requisitos

- macOS (Apple Silicon o Intel)
- [Homebrew](https://brew.sh) instalado
- Xcode Command Line Tools (trae `git`, `make`, un compilador de C):
  `xcode-select --install`

## Instalación

Antes de usar el modo `curl` en cualquiera de los scripts, edita `REPO_URL`
al principio de `install.sh`, `setup.sh` y `setup-nvim.sh` con la URL real
de este repo.

### Todo de una vez

Desde dentro del repo ya clonado:

```bash
bash install.sh
```

O sin clonar nada primero (clona el repo solo si hace falta, en `~/dotfiles`):

```bash
curl -fsSL https://raw.githubusercontent.com/<usuario>/<repo>/main/install.sh | bash
```

### Paso a paso

```bash
bash setup.sh        # Homebrew + zsh + tmux + symlinks del repo
bash setup-nvim.sh    # configuración de Neovim (LSP, treesitter, telescope...)
```

Cada script funciona igual de forma independiente (detecta el repo por su
cuenta, o lo clona si no lo encuentra) — `install.sh` solo evita tener que
acordarte de correr los dos.

## Qué hace cada script

### `setup.sh`

- Instala vía Homebrew: `zsh`, `tmux`, `neovim`, `starship`, `fzf`, `zoxide`,
  `eza`, `bat`, `fd`, `ripgrep`, `direnv`, `atuin`, `git-delta`, `lazygit`.
- Fija `ZDOTDIR=~/.config/zsh` globalmente en `/etc/zsh/zshenv`.
- Genera la config de zsh (`.zshrc`, `.zshenv`, `.zprofile`, `aliases.zsh`,
  `bindings.zsh`, `functions.zsh`, `plugins.zsh`, `fzf.zsh`) **solo si no
  existe ya** en el repo.
- Genera `tmux.conf` con TPM inicializado correctamente (mouse, sesiones
  persistentes vía tmux-resurrect/continuum).
- Enlaza `.config/zsh`, `.config/tmux`, `.config/nvim` y, si existe,
  `.config/starship.toml` del repo hacia `~/.config`.
- Configura `git-delta` como pager de git solo si no tenías uno ya definido.
- Hace backup de dotfiles previos (`~/.zshrc`, directorios reales donde
  antes iba un symlink, etc.) antes de tocar nada.

### `setup-nvim.sh`

- Genera una configuración completa de Neovim con `lazy.nvim`:
  - LSP vía `mason.nvim` + `mason-lspconfig` usando la API nativa
    `vim.lsp.config()` / `vim.lsp.enable()` (Neovim 0.11+) — no la API vieja
    de `nvim-lspconfig`, que quedó deprecada.
  - `nvim-treesitter` (fijado a la rama `master` — ver nota más abajo).
  - Telescope + `telescope-fzf-native`.
  - `blink.cmp` para autocompletado.
  - `lualine` (statusline), `gitsigns`, `which-key`, `nvim-autopairs`.
- Igual que `setup.sh`: solo escribe los archivos que no existen ya.

### `install.sh`

Corre `setup.sh` y luego `setup-nvim.sh` en orden. Nada más.

## Estructura del repo

```
.
├── install.sh
├── setup.sh
├── setup-nvim.sh
└── .config/
    ├── zsh/
    │   ├── .zshenv
    │   ├── .zshrc
    │   ├── .zprofile
    │   ├── aliases.zsh
    │   ├── bindings.zsh
    │   ├── functions.zsh
    │   ├── fzf.zsh
    │   └── plugins.zsh
    ├── tmux/
    │   └── tmux.conf
    ├── nvim/
    │   ├── init.lua
    │   └── lua/
    │       ├── config/       (options, keymaps, autocmds, bootstrap de lazy.nvim)
    │       └── plugins/      (un archivo por plugin/grupo de plugins)
    └── starship.toml         (opcional — ningún script lo genera)
```

## Decisiones de diseño

Para que nada de esto sorprenda dentro de seis meses:

- **Los archivos de config se generan una sola vez.** Si ya existen (porque
  los editaste y los commiteaste), los scripts no los tocan en ejecuciones
  posteriores. El repo manda, no el script.
- **Los plugins de terceros no viven en el repo.** Los de zsh van a
  `~/.local/share/zsh/plugins`, los de Neovim a donde los pone `lazy.nvim`
  (`~/.local/share/nvim/lazy`), y TPM a `~/.tmux/plugins/tpm`. Nada de esto
  se commitea ni debería.
- **`nvim-treesitter` está fijado a la rama `master`**, no a la rama por
  defecto del proyecto (que tuvo una reescritura incompatible con una API
  completamente distinta). Migrar a la rama nueva en el futuro es un cambio
  de API, no solo quitar una línea.
- **Node no se instala automáticamente.** `pyright`, `ts_ls` y `bashls` (vía
  Mason) lo necesitan. Si gestionas versiones de Node con nvm/fnm/mise,
  instálalo con tu herramienta habitual — el script solo avisa si falta, no
  te pisa esa gestión.
- **Ningún gestor de versiones (mise/nvm/pyenv) se activa por defecto en
  zsh**, por la misma razón.

## Después de instalar

- Abre una terminal nueva (o Ghostty) para que `ZDOTDIR` y el `shellenv` de
  Homebrew tomen efecto.
- Dentro de tmux: `prefix + I` instala los plugins de TPM.
- Dentro de Neovim: `lazy.nvim` instala todos los plugins solo en el primer
  arranque. Corre `:Mason` si necesitas un servidor LSP que no esté en la
  lista por defecto.
- Si el scaffolding creó archivos nuevos en el repo (primera ejecución),
  revísalos y haz commit: `git status`, `git add -A`, `git commit`.

## Requisitos por función

| Función                                          | Requiere                          |
|---------------------------------------------------|------------------------------------|
| `Telescope live_grep`                              | `ripgrep` (lo instala `setup.sh`) |
| Servidores LSP de Mason (`pyright`, `ts_ls`, `bashls`) | `node` + `npm` (no se instala solo) |
| Treesitter / `telescope-fzf-native`                | compilador de C (Xcode CLT)        |

## Atajos principales

- Zsh: `mkcd`, `extract`, `fkill`, `fbr` (funciones); Ctrl+R para historial
  (`atuin`); flechas arriba/abajo para búsqueda por substring.
- tmux: plugins con `prefix + I`; mouse activado; sesiones persistentes.
- Neovim: `<leader>ff/fg/fb/fh/fr/fd` (Telescope), `gd/gr/gI/K/<leader>rn/
  <leader>ca` (LSP), `]c/[c/<leader>hs/hr/hp/hb` (hunks de git), `gc`/`gcc`
  para comentarios (nativo de Neovim, sin plugin).
