# Load fzf keybindings & completion
# Path may differ depending on install method
if [[ -r "$(brew --prefix 2>/dev/null)/opt/fzf/shell/key-bindings.zsh" ]]; then
  source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
  source "$(brew --prefix)/opt/fzf/shell/completion.zsh"
elif [[ -r /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
fi

# --- Appearance ---
export FZF_DEFAULT_OPTS="
  --height 40%
  --layout=reverse
  --border
  --preview-window=right:60%
"

# --- Ctrl-T: file search ---
export FZF_CTRL_T_OPTS="
  --preview 'bat --style=numbers --color=always {} 2>/dev/null || cat {}'
"

# --- Ctrl-R: command history ---
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window=down:3:wrap
"
