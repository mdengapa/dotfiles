## 3. Configuración de Zsh Modular (.config/zsh/plugins.zsh)

Para evitar frameworks pesados, utiliza una función de carga manual para los 4 plugins recomendados:

```
function zplug() {
  PLUGIN_NAME=$(echo $1 | cut -d/ -f2)
  PLUGIN_DIR="$ZDOTDIR/plugins/$PLUGIN_NAME"
  if [ ! -d "$PLUGIN_DIR" ]; then
    git clone --depth 1 "https://github.com/$1.git" "$PLUGIN_DIR"
  fi
  source "$PLUGIN_DIR/$PLUGIN_NAME.plugin.zsh" 2>/dev/null || source "$PLUGIN_DIR/$PLUGIN_NAME.zsh"
}

zplug zsh-users/zsh-syntax-highlighting        # Resaltado visual
zplug zsh-users/zsh-autosuggestions            # Sugerencias históricas
zplug zsh-users/zsh-history-substring-search   # Búsqueda inteligente con flechas
zplug jeffreytse/zsh-vi-mode                   # Modo Vi en terminal
```
