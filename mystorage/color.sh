#!/bin/zsh

# inspiration: https://github.com/catppuccin/tmux/issues/90#issuecomment-1961298007
# thm_bg="#303446"
# thm_fg="#c6d0f5"
# thm_cyan="#99d1db"
# thm_black="#292c3c"
# thm_gray="#414559"
# thm_magenta="#ca9ee6"
# thm_pink="#f4b8e4"
# thm_red="#e78284"
# thm_green="#a6d189"
# thm_yellow="#e5c890"
# thm_blue="#8caaee"
# thm_orange="#ef9f76"
# thm_black4="#626880"
get_current_storage_color() {
  if [[ "$(uname)" == "Darwin" ]]; then
    current_storage="$(df -k / | awk 'NR==2 {printf "%.2f\n", ($4 / $2) * 100}')"
    if (( current_storage <= 15 )); then
      echo "#e78284" # thm_red
    elif (( current_storage <= 40 )); then
      echo "#e5c890" # thm_yellow
    else
      echo "#a6d189" #thm_green
    fi
  else
    echo "#ef9f76" #thm_orange
  fi
}

get_current_storage_color
