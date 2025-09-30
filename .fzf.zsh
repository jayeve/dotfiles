# Setup fzf
if [[ ! "$PATH" == *$HOME/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}$HOME/.fzf/bin"
fi

# Auto-completion
source_if_exists "$HOME/.fzf/shell/completion.zsh"
# Key bindings
source_if_exists "$HOME/.fzf/shell/key-bindings.zsh"
