#!/usr/bin/env bash
#
# setup.sh — Bootstrap único: Homebrew + zsh + tmux, usando un repo de dotfiles
#            como fuente de verdad para la configuración.
#
# Uso:
#   Desde dentro de tu repo de dotfiles ya clonado:
#     bash setup.sh
#   O cargado directo (clona el repo solo si no lo tienes ya):
#     curl -fsSL https://raw.githubusercontent.com/mdengapa/dotfiles/main/setup.sh | bash
#   Antes de usar el modo curl, edita REPO_URL más abajo.
#
# Requisito: Homebrew y Xcode Command Line Tools (git) ya instalados.
#
# ---------------------------------------------------------------------------
# DECISIONES DE DISEÑO (léelas antes de asumir que hace lo mismo que antes):
#
# 1. Los archivos de configuración (.zshrc, .zshenv, aliases.zsh, tmux.conf...)
#    se generan SOLO SI NO EXISTEN YA en el repo. Primera ejecución: los crea.
#    Ejecuciones siguientes: si ya los editaste y los tienes commiteados, no
#    los toca. Esto es intencional — antes este script sobreescribía esos
#    archivos en cada ejecución, lo cual rompe el propósito de tener un repo
#    de dotfiles versionado.
#
# 2. Los plugins de zsh (autosuggestions, syntax-highlighting, etc.) y
#    zsh-completions ya NO se clonan dentro del repo. Antes acababan bajo
#    $ZDOTDIR/plugins, que con el symlink al repo significaba vendorizar
#    código de terceros dentro de tu propio repo git. Ahora van a
#    ~/.local/share/zsh/plugins (XDG_DATA_HOME), fuera de cualquier repo.
#
# 3. starship.toml solo se enlaza si YA existe en el repo. No se genera un
#    tema por defecto. Y ya no se fuerza STARSHIP_CONFIG — starship busca
#    ~/.config/starship.toml por defecto, que es justo donde queda el symlink.
#    (Antes STARSHIP_CONFIG apuntaba a $ZDOTDIR/starship.toml mientras el
#    symlink lo dejaba en ~/.config/starship.toml: nunca coincidían.)
#
# 4. tmux.conf ahora se genera con TPM correctamente referenciado (antes se
#    clonaba TPM pero el tmux.conf simlinkeado no garantizaba usarlo).
#
# 5. La configuración de Neovim queda fuera de este script a propósito
#    (vendrá en otro script aparte). Aquí solo se prepara la carpeta y el
#    symlink para que ese script tenga dónde escribir.
# ---------------------------------------------------------------------------

set -euo pipefail

log()  { printf '\033[1;34m[setup]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[setup][aviso]\033[0m %s\n' "$*"; }

if [[ "$(uname -s)" != "Darwin" ]]; then
  warn "Pensado para macOS. Continúo, pero la sección de Homebrew se saltará si no hay brew."
fi

REPO_URL="https://github.com/mdengapa/dotfiles.git"
DEFAULT_REPO_DIR="$HOME/dotfiles"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="$HOME/.dotfiles_backup_$TIMESTAMP"
BACKUP_USED=false

backup_and_remove() {
  # Si $1 existe y NO es ya un symlink, lo mueve a BACKUP_DIR antes de tocarlo.
  local path="$1"
  if [ -e "$path" ] && [ ! -L "$path" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$path" "$BACKUP_DIR/$(basename "$path")"
    BACKUP_USED=true
    warn "Backup: $path -> $BACKUP_DIR/$(basename "$path")"
  fi
}

link_config() {
  # $1 = origen real (dentro del repo), $2 = destino (symlink en $HOME)
  local src="$1" dest="$2"
  backup_and_remove "$dest"
  ln -sf "$src" "$dest"
  log "Enlazado: $dest -> $src"
}

# ---------------------------------------------------------------------------
# 0. Localizar (o clonar) el repo de dotfiles
# ---------------------------------------------------------------------------
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" 2>/dev/null && pwd || true)"

if [ -n "$SCRIPT_DIR" ] && git -C "$SCRIPT_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
  REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
  log "Repo de dotfiles detectado en: $REPO_ROOT"
else
  REPO_ROOT="$DEFAULT_REPO_DIR"
  if [ -d "$REPO_ROOT/.git" ]; then
    log "Repo ya existe en $REPO_ROOT, no lo vuelvo a clonar."
  else
    log "No estoy dentro de un repo git. Clonando dotfiles en $REPO_ROOT..."
    git clone "$REPO_URL" "$REPO_ROOT"
  fi
fi

# ---------------------------------------------------------------------------
# 1. Backup de dotfiles sueltos en $HOME (dejan de leerse al mover ZDOTDIR)
# ---------------------------------------------------------------------------
for f in .zshrc .zshenv .zprofile .zlogin; do
  backup_and_remove "$HOME/$f"
done

# ---------------------------------------------------------------------------
# 2. Homebrew — paquetes base, incluye tmux
# ---------------------------------------------------------------------------
if command -v brew >/dev/null 2>&1; then
  log "Instalando paquetes de Homebrew..."
  PACKAGES=(zsh tmux neovim starship fzf zoxide eza bat fd ripgrep direnv atuin git-delta lazygit)
  FAILED=()
  for pkg in "${PACKAGES[@]}"; do
    if ! brew list --formula "$pkg" >/dev/null 2>&1; then
      brew install "$pkg" || FAILED+=("$pkg")
    fi
  done
  [ "${#FAILED[@]}" -gt 0 ] && warn "No se pudieron instalar: ${FAILED[*]}"
else
  warn "Homebrew no está instalado o no está en el PATH de esta sesión. Instálalo primero: https://brew.sh"
fi

# ---------------------------------------------------------------------------
# 3. Estructura de directorios XDG (fuera del repo)
# ---------------------------------------------------------------------------
mkdir -p ~/.config ~/.cache/zsh ~/.local/state/zsh ~/.local/bin ~/.local/share/zsh/plugins

# ---------------------------------------------------------------------------
# 4. Esqueleto del repo — solo crea carpetas, no pisa nada existente
# ---------------------------------------------------------------------------
mkdir -p "$REPO_ROOT/.config/zsh" "$REPO_ROOT/.config/tmux" "$REPO_ROOT/.config/nvim"

# ---------------------------------------------------------------------------
# 5. Scaffolding de zsh — SOLO si el archivo no existe ya en el repo
# ---------------------------------------------------------------------------
ZSH_DIR="$REPO_ROOT/.config/zsh"

if [ ! -f "$ZSH_DIR/.zshenv" ]; then
cat > "$ZSH_DIR/.zshenv" <<'EOF'
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export EDITOR="nvim"
export PAGER="less -R"
export MANPAGER="bash -c 'col -bx | bat -l man -p'"
export PATH="$HOME/.local/bin:$PATH"
# Sin STARSHIP_CONFIG: starship ya busca ~/.config/starship.toml por defecto,
# que es justo donde queda enlazado starship.toml del repo (si existe).
EOF
fi

if [ ! -f "$ZSH_DIR/.zprofile" ]; then
cat > "$ZSH_DIR/.zprofile" <<'EOF'
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
EOF
fi

if [ ! -f "$ZSH_DIR/.zshrc" ]; then
cat > "$ZSH_DIR/.zshrc" <<'EOF'
# Historial
HISTFILE="$XDG_STATE_HOME/zsh/history"
HISTSIZE=100000
SAVEHIST=100000
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt AUTO_CD

# zsh-completions: tiene que estar en fpath ANTES de compinit.
ZSH_COMPLETIONS_DIR="$XDG_DATA_HOME/zsh/plugins/zsh-completions"
if [ ! -d "$ZSH_COMPLETIONS_DIR" ]; then
  git clone --depth 1 https://github.com/zsh-users/zsh-completions.git "$ZSH_COMPLETIONS_DIR" >/dev/null 2>&1
fi
[ -d "$ZSH_COMPLETIONS_DIR/src" ] && fpath=("$ZSH_COMPLETIONS_DIR/src" $fpath)

# Autocompletado (-u evita bloqueos por permisos de directorios de Homebrew)
mkdir -p "$XDG_CACHE_HOME/zsh"
autoload -Uz compinit && compinit -u -d "$XDG_CACHE_HOME/zsh/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':fzf-tab:*' fzf-flags --height=40%

# Prompt / navegación (después de compinit)
if command -v zoxide >/dev/null 2>&1; then eval "$(zoxide init zsh)"; fi
if command -v starship >/dev/null 2>&1; then eval "$(starship init zsh)"; fi

# Módulos
source "$ZDOTDIR/aliases.zsh"
source "$ZDOTDIR/bindings.zsh"
source "$ZDOTDIR/fzf.zsh"
source "$ZDOTDIR/functions.zsh"
source "$ZDOTDIR/plugins.zsh"

# direnv y atuin al final (convención de sus propios proyectos, y para que
# sus keybindings/hooks ganen sobre los de los plugins anteriores).
if command -v direnv >/dev/null 2>&1; then eval "$(direnv hook zsh)"; fi
if command -v atuin >/dev/null 2>&1; then
  # --disable-up-arrow: dejamos la flecha arriba para history-substring-search.
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# Gestor de versiones (Node/Python/Ruby) — DESACTIVADO a propósito.
# Si ya usas nvm/pyenv/rbenv, activar esto sin revisar te puede pisar el PATH.
# brew install mise && descomenta:
# eval "$(mise activate zsh)"
EOF
fi

if [ ! -f "$ZSH_DIR/fzf.zsh" ]; then
cat > "$ZSH_DIR/fzf.zsh" <<'EOF'
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
  export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --preview 'bat --style=numbers --color=always {} | head -500'"
fi
EOF
fi

if [ ! -f "$ZSH_DIR/plugins.zsh" ]; then
cat > "$ZSH_DIR/plugins.zsh" <<'EOF'
function zplug() {
  local PLUGIN_NAME PLUGIN_DIR
  PLUGIN_NAME=$(echo "$1" | cut -d/ -f2)
  # Fuera del repo a propósito: son clones de terceros, no config tuya.
  PLUGIN_DIR="$XDG_DATA_HOME/zsh/plugins/$PLUGIN_NAME"
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

# Orden (no arbitrario):
#  1. fzf-tab: tras compinit, antes de plugins que envuelvan widgets.
#  2. autosuggestions / history-substring-search / vi-mode: sin orden estricto entre ellos.
#  3. zsh-syntax-highlighting: SIEMPRE el último.
zplug Aloxaf/fzf-tab
zplug zsh-users/zsh-autosuggestions
zplug zsh-users/zsh-history-substring-search
zplug jeffreytse/zsh-vi-mode
zplug zsh-users/zsh-syntax-highlighting
EOF
fi

if [ ! -f "$ZSH_DIR/bindings.zsh" ]; then
cat > "$ZSH_DIR/bindings.zsh" <<'EOF'
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

ZVM_INSERT_MODE_CURSOR=beam
ZVM_NORMAL_MODE_CURSOR=block
EOF
fi

if [ ! -f "$ZSH_DIR/functions.zsh" ]; then
cat > "$ZSH_DIR/functions.zsh" <<'EOF'
mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}

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

fkill() {
  local pids
  pids=$(ps -ef | sed 1d | fzf -m --header='Selecciona proceso(s) a matar (Tab = multi-selección)' | awk '{print $2}')
  if [ -n "$pids" ]; then
    echo "$pids" | xargs kill -"${1:-9}"
  fi
}

fbr() {
  local branch
  branch=$(git branch --all 2>/dev/null | grep -v HEAD | sed 's/^..//' | sed 's#remotes/[^/]*/##' | sort -u | fzf --height 40% --reverse)
  [ -n "$branch" ] && git checkout "$branch"
}
EOF
fi

if [ ! -f "$ZSH_DIR/aliases.zsh" ]; then
cat > "$ZSH_DIR/aliases.zsh" <<'EOF'
alias ls="eza --icons"
alias ll="eza -l --icons --git"
alias la="eza -ah --icons --git"
alias cat="bat"
alias grep="rg"
alias vim="nvim"
alias g="git"
EOF
fi

# ---------------------------------------------------------------------------
# 6. Scaffolding de tmux — SOLO si no existe ya en el repo
# ---------------------------------------------------------------------------
if [ ! -f "$REPO_ROOT/.config/tmux/tmux.conf" ]; then
cat > "$REPO_ROOT/.config/tmux/tmux.conf" <<'EOF'
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
set -g history-limit 10000
set -sg escape-time 0
set -g default-terminal "tmux-256color"
set -ga terminal-overrides ",xterm-256color:Tc"

bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

bind r source-file ~/.config/tmux/tmux.conf \; display "Config recargada"

# Plugins (TPM) — instalar/actualizar con prefix + I dentro de una sesión tmux
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @continuum-restore 'on'

# Esta línea tiene que ser la ÚLTIMA del archivo (requisito de TPM)
run '~/.tmux/plugins/tpm/tpm'
EOF
fi

# ---------------------------------------------------------------------------
# 7. ZDOTDIR global en /etc/zsh/zshenv — solo se añade si no está ya
# ---------------------------------------------------------------------------
ZSHENV_MARKER="# managed-by: setup.sh"
if ! sudo grep -qF "$ZSHENV_MARKER" /etc/zsh/zshenv 2>/dev/null; then
  log "Añadiendo ZDOTDIR a /etc/zsh/zshenv (pide sudo)..."
  sudo tee -a /etc/zsh/zshenv > /dev/null <<'EOF'

# managed-by: setup.sh
export XDG_CONFIG_HOME="${HOME}/.config"
export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"
EOF
else
  log "/etc/zsh/zshenv ya tiene el bloque de ZDOTDIR, no se toca."
fi

# ---------------------------------------------------------------------------
# 8. Symlinks del repo hacia ~/.config
# ---------------------------------------------------------------------------
link_config "$REPO_ROOT/.config/zsh"  "$HOME/.config/zsh"
link_config "$REPO_ROOT/.config/tmux" "$HOME/.config/tmux"
link_config "$REPO_ROOT/.config/nvim" "$HOME/.config/nvim"

if [ -f "$REPO_ROOT/.config/starship.toml" ]; then
  link_config "$REPO_ROOT/.config/starship.toml" "$HOME/.config/starship.toml"
else
  log "No hay starship.toml en el repo, starship usará su prompt por defecto."
fi

# ---------------------------------------------------------------------------
# 9. TPM (gestor de plugins de tmux) — fuera del repo, como los plugins de zsh
# ---------------------------------------------------------------------------
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  log "Clonando TPM..."
  git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
  log "TPM ya está clonado."
fi

# ---------------------------------------------------------------------------
# 10. git-delta — solo si no tenías ya un core.pager propio
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Resumen
# ---------------------------------------------------------------------------
log "Configuración completada."
log "Repo de dotfiles: $REPO_ROOT"
log "Abre una terminal nueva (o Ghostty) para que ZDOTDIR y brew shellenv tomen efecto."
log "Dentro de tmux, pulsa prefix + I para instalar los plugins de TPM."
if $BACKUP_USED; then
  log "Hubo backups de archivos/directorios previos en: $BACKUP_DIR"
fi
if [ ! -d "$REPO_ROOT/.git" ] || [ -n "$(git -C "$REPO_ROOT" status --porcelain 2>/dev/null)" ]; then
  warn "El repo tiene cambios sin commitear (probablemente el scaffolding de esta ejecución). Revisa y haz commit: cd $REPO_ROOT && git status"
fi
