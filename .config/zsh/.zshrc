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
