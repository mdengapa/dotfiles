# Estructura de Dotfiles que respete el estándar XDG. El objetivo es que todas las configuraciones residan en ~/.config/ y que un solo script de instalación (setup.sh) se encargue de vincular todo y descargar las herramientas necesarias.

## Estructura del Repositorio en GitHub
.
├── setup.sh                # Script principal de automatización
├── .config/
│   ├── zsh/                # Configuración modular de Zsh (fuente [3])
│   │   ├── .zshrc
│   │   ├── aliases.zsh
│   │   ├── bindings.zsh
│   │   └── plugins.zsh
│   ├── nvim/               # Estructura modular de Neovim (fuentes [4, 5])
│   │   ├── init.lua
│   │   └── lua/
│   │       ├── config/     # opciones, keymaps, globals
│   │       ├── plugins/    # archivos de lazy.nvim
│   │       └── servers/    # configuraciones de LSP (fuente [6])
│   ├── tmux/               # Configuración de Tmux (fuente [7])
│   │   ├── tmux.conf
│   │   └── scripts/        # Scripts personalizados (fuente [8])
│   └── starship.toml       # Tema del prompt (fuente [9])
└── .zshenv                 # Variables de entorno globales (fuente [2])
