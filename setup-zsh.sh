#!/usr/bin/env bash
#
# setup-zsh.sh — Configuración zsh modular (XDG) para macOS
#
# Uso:
#   curl -fsSL https://raw.githubusercontent.com/<usuario>/<repo>/main/setup-zsh.sh | bash
#
# Qué corrige respecto a la versión anterior:
#   - Heredocs limpios (sin marcadores tipo "EOF [1]" que rompían el parseo).
#   - No pisa /etc/zsh/zshenv a ciegas: solo añade el bloque si no está ya presente.
#   - Migra el arranque de Homebrew (brew shellenv) a $ZDOTDIR/.zprofile, porque
#     al mover ZDOTDIR, ~/.zprofile deja de leerse y brew desaparece del PATH.
#   - Hace backup de .zshrc/.zshenv/.zprofile/.zlogin existentes antes de tocar nada.
#   - Orden de plugins corregido: zsh-syntax-highlighting se carga el último
#     (requisito documentado por el propio proyecto).
#   - compinit con -u para no colgarse en avisos de "insecure directories".
#   - starship/zoxide se inicializan después de compinit.
#   - brew install con manejo de errores por paquete (uno que falle no tira abajo el resto).
#
# Superpowers añadidos:
#   - fzf-tab (menús de completado con fzf), zsh-completions (más completados).
#   - direnv (env vars por directorio), atuin (historial buscable, local por defecto).
#   - git-delta + lazygit, configurados solo si no tenías ya un core.pager propio.
#   - functions.zsh: mkcd, extract, fkill, fbr.
#   - mise queda comentado a propósito: si ya usas nvm/pyenv/rbenv, activarlo
#     sin más te puede pisar el PATH de esas herramientas.
#
set -euo pipefail

log()  { printf '\033[1;34m[setup-zsh]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[setup-zsh][aviso]\033[0m %s\n' "$*"; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  warn "Este script está pensado para macOS. Continúo, pero la sección de Homebrew se saltará si no hay brew."
fi

# ---------------------------------------------------------------------------
# 0. Backup de dotfiles existentes (no se toca ni se borra nada sin copia)
# ---------------------------------------------------------------------------
BACKUP_DIR="$HOME/.zsh_backup_$(date +%Y%m%d_%H%M%S)"
NEED_BACKUP=false
for f in .zshrc .zshenv .zprofile .zlogin; do
  [[ -f "$HOME/$f" && ! -L "$HOME/$f" ]] && NEED_BACKUP=true
done
if $NEED_BACKUP; then
  mkdir -p "$BACKUP_DIR"
  for f in .zshrc .zshenv .zprofile .zlogin; do
    if [[ -f "$HOME/$f" && ! -L "$HOME/$f" ]]; then
      cp "$HOME/$f" "$BACKUP_DIR/"
      log "Backup: ~/$f -> $BACKUP_DIR/$f"
    fi
  done
  warn "Revisa $BACKUP_DIR: si tenías configuración propia en esos archivos, este script NO la migra automáticamente (solo el arranque de Homebrew)."
fi

# ---------------------------------------------------------------------------
# 1. Estructura de directorios XDG
# ---------------------------------------------------------------------------
mkdir -p ~/.config/zsh/plugins
mkdir -p ~/.cache/zsh
mkdir -p ~/.local/state/zsh
mkdir -p ~/.local/bin

# ---------------------------------------------------------------------------
# 2. ZDOTDIR global en /etc/zsh/zshenv — solo se añade si no está ya
# ---------------------------------------------------------------------------
ZSHENV_MARKER="# managed-by: setup-zsh.sh"
if ! sudo grep -qF "$ZSHENV_MARKER" /etc/zsh/zshenv 2>/dev/null; then
  log "Añadiendo ZDOTDIR a /etc/zsh/zshenv (pide sudo)..."
  sudo tee -a /etc/zsh/zshenv > /dev/null <<'EOF'

# managed-by: setup-zsh.sh
export XDG_CONFIG_HOME="${HOME}/.config"
export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"
EOF
else
  log "/etc/zsh/zshenv ya tiene el bloque de ZDOTDIR, no se toca."
fi

# ---------------------------------------------------------------------------
# 3. $ZDOTDIR/.zshenv — variables de entorno y PATH
# ---------------------------------------------------------------------------
cat > ~/.config/zsh/.zshenv <<'EOF'
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export EDITOR="nvim"
export PAGER="less -R"
export MANPAGER="bash -c 'col -bx | bat -l man -p'"
export PATH="$HOME/.local/bin:$PATH"
export STARSHIP_CONFIG="$ZDOTDIR/starship.toml"
EOF

# ---------------------------------------------------------------------------
# 3b. $ZDOTDIR/.zprofile — arranque de Homebrew (login shells)
#     Esto es lo que evita que brew desaparezca del PATH al mover ZDOTDIR.
# ---------------------------------------------------------------------------
cat > ~/.config/zsh/.zprofile <<'EOF'
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
EOF

# ---------------------------------------------------------------------------
# 4. $ZDOTDIR/.zshrc — carga modular
# ---------------------------------------------------------------------------
cat > ~/.config/zsh/.zshrc <<'EOF'
# Historial
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt AUTO_CD

# zsh-completions: tiene que estar en fpath ANTES de compinit, por eso no
# pasa por el mismo mecanismo que el resto de plugins (que cargan después).
ZSH_COMPLETIONS_DIR="$ZDOTDIR/plugins/zsh-completions"
if [ ! -d "$ZSH_COMPLETIONS_DIR" ]; then
  git clone --depth 1 https://github.com/zsh-users/zsh-completions.git "$ZSH_COMPLETIONS_DIR" >/dev/null 2>&1
fi
[ -d "$ZSH_COMPLETIONS_DIR/src" ] && fpath=("$ZSH_COMPLETIONS_DIR/src" $fpath)

# Autocompletado (con -u para no bloquear por permisos de directorios de Homebrew)
mkdir -p "$XDG_CACHE_HOME/zsh"
autoload -Uz compinit && compinit -u -d "$XDG_CACHE_HOME/zsh/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':fzf-tab:*' fzf-flags --height=40%

# Herramientas de prompt/navegación (después de compinit)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Módulos
source "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/bindings.zsh"
source "$ZDOTDIR/fzf.zsh"
source "$ZDOTDIR/functions.zsh"
source "$ZDOTDIR/plugins.zsh"

# direnv y atuin van al final: por convención de sus propios proyectos,
# y para que sus keybindings/hooks ganen sobre los de los plugins anteriores.
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi
if command -v atuin >/dev/null 2>&1; then
  # --disable-up-arrow: dejamos la flecha arriba para history-substring-search,
  # que ya está configurado en bindings.zsh. Ctrl+R queda para atuin.
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# Gestor de versiones (Node/Python/Ruby/...) — DESACTIVADO a propósito.
# Si ya usas nvm, pyenv o rbenv en algún proyecto, activar esto sin revisar
# puede pisarte el PATH de esas herramientas. Si quieres mise, instala con
# `brew install mise` y descomenta la línea siguiente:
# eval "$(mise activate zsh)"
EOF

# ---------------------------------------------------------------------------
# 5. FZF con vista previa
# ---------------------------------------------------------------------------
cat > ~/.config/zsh/fzf.zsh <<'EOF'
# Configuración para Mac con Homebrew
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview 'bat --style=numbers --color=always {} | head -500'"
fi
EOF

# ---------------------------------------------------------------------------
# 6. Plugins — orden importa: zsh-syntax-highlighting SIEMPRE al final,
#    porque envuelve widgets ya creados por los plugins anteriores.
# ---------------------------------------------------------------------------
cat > ~/.config/zsh/plugins.zsh <<'EOF'
function zplug() {
  local PLUGIN_NAME PLUGIN_DIR
  PLUGIN_NAME=$(echo "$1" | cut -d/ -f2)
  PLUGIN_DIR="$ZDOTDIR/plugins/$PLUGIN_NAME"
  if [ ! -d "$PLUGIN_DIR" ]; then
    echo "Instalando plugin: $PLUGIN_NAME..."
    git clone --depth 1 "https://github.com/$1.git" "$PLUGIN_DIR" || {
      echo "Error clonando $1, se omite." >&2
      return 1
    }
  fi
  if [ -f "$PLUGIN_DIR/$PLUGIN_NAME.plugin.zsh" ]; then
    source "$PLUGIN_DIR/$PLUGIN_NAME.plugin.zsh"
  elif [ -f "$PLUGIN_DIR/$PLUGIN_NAME.zsh" ]; then
    source "$PLUGIN_DIR/$PLUGIN_NAME.zsh"
  else
    echo "No se encontró archivo fuente para $PLUGIN_NAME en $PLUGIN_DIR" >&2
  fi
}

# Orden (no es arbitrario, cada uno tiene requisito documentado):
#  1. fzf-tab: después de compinit (ya lo está, se llama tras source de este
#     archivo... en realidad compinit corre ANTES en .zshrc), pero antes de
#     cualquier plugin que envuelva widgets (autosuggestions, syntax-highlighting).
#  2. autosuggestions / history-substring-search / vi-mode: sin requisito de
#     orden estricto entre ellos.
#  3. zsh-syntax-highlighting: SIEMPRE el último, envuelve todo lo anterior.
zplug Aloxaf/fzf-tab
zplug zsh-users/zsh-autosuggestions
zplug zsh-users/zsh-history-substring-search
zplug jeffreytse/zsh-vi-mode
zplug zsh-users/zsh-syntax-highlighting
EOF

# ---------------------------------------------------------------------------
# 7. Bindings — sustring-search y vi-mode
# ---------------------------------------------------------------------------
cat > ~/.config/zsh/bindings.zsh <<'EOF'
# Búsqueda con flechas arriba/abajo usando substring-search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# Configuración de cursor para Vi-Mode
ZVM_INSERT_MODE_CURSOR=beam
ZVM_NORMAL_MODE_CURSOR=block
EOF

# ---------------------------------------------------------------------------
# 7b. Funciones sueltas
# ---------------------------------------------------------------------------
cat > ~/.config/zsh/functions.zsh <<'EOF'
# mkcd: crea un directorio y entra en él
mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

# extract: extractor universal de archivos comprimidos
extract() {
  if [ ! -f "$1" ]; then
    echo "'$1' no es un archivo válido" >&2
    return 1
  fi
  case "$1" in
    *.tar.bz2) tar xjf "$1"    ;;
    *.tar.gz)  tar xzf "$1"    ;;
    *.tar.xz)  tar xJf "$1"    ;;
    *.tbz2)    tar xjf "$1"    ;;
    *.tgz)     tar xzf "$1"    ;;
    *.tar)     tar xf "$1"     ;;
    *.bz2)     bunzip2 "$1"    ;;
    *.gz)      gunzip "$1"     ;;
    *.zip)     unzip "$1"      ;;
    *.rar)     unrar x "$1"    ;;
    *.7z)      7z x "$1"       ;;
    *.Z)       uncompress "$1" ;;
    *)         echo "No sé descomprimir '$1'" >&2 ;;
  esac
}

# fkill: mata procesos seleccionados con fzf (Tab = multi-selección)
fkill() {
  local pids
  pids=$(ps -ef | sed 1d | fzf -m --header='Selecciona proceso(s) a matar (Tab = multi-selección)' | awk '{print $2}')
  if [ -n "$pids" ]; then
    echo "$pids" | xargs kill -"${1:-9}"
  fi
}

# fbr: cambia de rama de git eligiendo con fzf (incluye remotas)
fbr() {
  local branch
  branch=$(git branch --all 2>/dev/null | grep -v HEAD | sed 's/^..//' | sed 's#remotes/[^/]*/##' | sort -u | fzf --height 40% --reverse)
  [ -n "$branch" ] && git checkout "$branch"
}
EOF

# ---------------------------------------------------------------------------
# 8. Alias
# ---------------------------------------------------------------------------
cat > ~/.config/zsh/aliases.zsh <<'EOF'
alias ls="eza --icons"
alias ll="eza -l --icons --git"
alias la="eza -ah --icons --git"
alias cat="bat"
alias grep="rg"
alias vim="nvim"
alias g="git"
EOF

# ---------------------------------------------------------------------------
# 9. Homebrew — instalación de herramientas base
# ---------------------------------------------------------------------------
if command -v brew >/dev/null 2>&1; then
  log "Instalando paquetes de Homebrew..."
  PACKAGES=(zoxide fzf starship eza bat fd ripgrep neovim direnv atuin git-delta lazygit)
  FAILED=()
  for pkg in "${PACKAGES[@]}"; do
    if ! brew list --formula "$pkg" >/dev/null 2>&1; then
      brew install "$pkg" || FAILED+=("$pkg")
    fi
  done
  if [ "${#FAILED[@]}" -gt 0 ]; then
    warn "No se pudieron instalar: ${FAILED[*]}"
  fi

  # git-delta: solo lo activo como pager si no tenías ya uno definido.
  # Si ya tienes core.pager configurado, no te lo piso.
  if command -v delta >/dev/null 2>&1; then
    CURRENT_PAGER="$(git config --global core.pager 2>/dev/null || true)"
    if [ -z "$CURRENT_PAGER" ]; then
      git config --global core.pager "delta"
      git config --global interactive.diffFilter "delta --color-only"
      git config --global delta.navigate true
      git config --global merge.conflictstyle "diff3"
      log "git configurado para usar delta como pager."
    else
      warn "git ya tiene core.pager=$CURRENT_PAGER; no lo toco. Para usar delta: git config --global core.pager delta"
    fi
  fi
else
  warn "Homebrew no está instalado o no está en el PATH de esta sesión. Instala Homebrew primero: https://brew.sh"
fi

log "Configuración completada."
log "Abre una terminal nueva (o Ghostty) para que ZDOTDIR y brew shellenv tomen efecto."
if $NEED_BACKUP; then
  log "Backup de tus dotfiles anteriores en: $BACKUP_DIR"
fi
