# dotfiles

## Estructura de Dotfiles que respete el estándar XDG. 

El objetivo es que todas las configuraciones residan en ~/.config/ y que un solo script de instalación (setup.sh) se encargue de vincular todo y descargar las herramientas necesarias.

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
**Zoxide (z):** Un reemplazo inteligente para cd que "aprende" los directorios que más visitas, permitiéndote saltar a ellos instantáneamente con solo escribir una parte del nombre.

**FZF (Fuzzy Finder):** Se utiliza para búsquedas borrosas en el historial (Ctrl+R) y en los archivos del directorio actual (Ctrl+T), permitiéndote encontrar lo que buscas incluso si no recuerdas el nombre exacto.En el archivo fzf.zsh, configura bat como motor de vista previa para ver el contenido de los archivos mientras buscas.

**Starship:** Un prompt extremadamente rápido y personalizable que funciona en cualquier sistema y te da información visual sobre el estado de Git y el entorno en una sola línea.Coloca el archivo starship.toml directamente en el repo y asegúrate de que .zshenv tenga la variable STARSHIP_CONFIG apuntando a la ruta correcta dentro de tu configuración de Zsh.

**Gestión de Historial:** Asegúrate de que tu .zshrc apunte el historial a ~/.local/state/zsh/history para mantener limpia tu carpeta de configuración.

# Ejemplo de automatización para tu script
```
if [ ! -f "$HOME/.tmux.conf" ]; then
  echo "Descargando configuración de Tmux desde GitHub..."
  curl -o "$HOME/.tmux.conf" https://raw.githubusercontent.com/mdengapa/dotfiles/main/.tmux.conf
fi
```

