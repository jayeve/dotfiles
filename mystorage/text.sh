#!/bin/zsh

# inspiration: https://github.com/catppuccin/tmux/issues/90#issuecomment-1961298007
get_current_storage_text() {
  if [[ "$(uname)" == "Darwin" ]]; then
    current_storage="$(df -k / | awk 'NR==2 {printf "%.2f\n", ($4 / $2) * 100}')"
    echo "$current_storage%"
  else
    echo "ERR: Not OSX"
  fi
}

get_current_storage_text
