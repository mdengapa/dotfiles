#!/usr/bin/env bash
#
# install.sh — Punto de entrada único: corre setup.sh y luego setup-nvim.sh.
#
# Uso:
#   Desde dentro del repo ya clonado:
#     bash install.sh
#   O cargado directo (clona el repo solo si no lo tienes ya):
#     curl -fsSL https://raw.githubusercontent.com/<usuario>/<repo>/main/install.sh | bash
#   Antes de usar el modo curl, edita REPO_URL más abajo (y en setup.sh /
#   setup-nvim.sh, que hacen la misma comprobación por su cuenta).
#
set -euo pipefail
trap 'echo "[ERROR] Fallo en la línea $LINENO (comando: $BASH_COMMAND)" >&2' ERR

log()  { printf '\033[1;34m[install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[install][aviso]\033[0m %s\n' "$*"; }

REPO_URL="https://github.com/mdengapa/dotfiles.git"
DEFAULT_REPO_DIR="$HOME/dotfiles"

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

for script in setup.sh setup-nvim.sh; do
  if [ ! -f "$REPO_ROOT/$script" ]; then
    echo "No encuentro $REPO_ROOT/$script. ¿Está el repo completo?" >&2
    exit 1
  fi
done

log "Ejecutando setup.sh (Homebrew, zsh, tmux, symlinks)..."
bash "$REPO_ROOT/setup.sh"

log "Ejecutando setup-nvim.sh (Neovim: LSP, treesitter, telescope...)..."
bash "$REPO_ROOT/setup-nvim.sh"

log "Todo listo. Abre una terminal nueva (o Ghostty) para que los cambios tomen efecto."
