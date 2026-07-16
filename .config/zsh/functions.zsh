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
