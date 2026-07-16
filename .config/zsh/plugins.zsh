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
