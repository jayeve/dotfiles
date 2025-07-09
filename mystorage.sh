# place at ~/.tmux/plugins/tmux/custom/mystorage.sh
show_mystorage() { # This function name must match the module name!
  local index icon color text module

  index=$1 # This variable is used internally by the module loader in order to know the position of this module

  # color="$(get_tmux_option "@catppuccin_mystorage_color" "$thm_green" )"
  # https://www.nerdfonts.com/cheat-sheet
  icon="$(get_tmux_option "@catppuccin_mystorage_icon"  "#($HOME/dotfiles/mystorage/icon.sh)")"
  color="$(get_tmux_option "@catppuccin_mystorage_color" "#($HOME/dotfiles/mystorage/color.sh)" )"
  text="$(get_tmux_option "@catppuccin_mystorage_text" "#($HOME/dotfiles/mystorage/text.sh)")"
  module=$(build_status_module "$index" "$icon" "$color" "$text" )

  echo "$module"
}
