#!/bin/zsh

# inspiration: https://github.com/catppuccin/tmux/issues/90#issuecomment-1961298007
get_current_storage_text() {
  if [[ "$(uname)" == "Darwin" ]]; then
    current_storage="$(df -h / | awk 'NR==2 {gsub("%","",$5); print 100 - $5}')"
    echo "$current_storage%"
  else
    echo "ERR: Not OSX"
  fi
}

get_current_storage_text
