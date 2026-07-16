## Estructura de Dotfiles que respete el estándar XDG. El objetivo es que todas las configuraciones residan en ~/.config/ y que un solo script de instalación (setup.sh) se encargue de vincular todo y descargar las herramientas necesarias.

### Estructura del Repositorio en GitHub
```
.
├── setup.sh                # Script principal de automatización
├── .config/
│   ├── zsh/                # Configuración modular de Zsh
│   │   ├── .zshrc
│   │   ├── aliases.zsh
│   │   ├── bindings.zsh
│   │   └── plugins.zsh
│   ├── nvim/               # Estructura modular de Neovim
│   │   ├── init.lua
│   │   └── lua/
│   │       ├── config/     # opciones, keymaps, globals
│   │       ├── plugins/    # archivos de lazy.nvim
│   │       └── servers/    # configuraciones de LSP
│   ├── tmux/               # Configuración de Tmux
│   │   ├── tmux.conf
│   │   └── scripts/        # Scripts personalizados
│   └── starship.toml       # Tema del prompt
└── .zshenv                 # Variables de entorno globales
```
