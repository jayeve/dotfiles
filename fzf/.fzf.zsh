# Load fzf keybindings & completion
# Supports macOS (Homebrew) and Linux (apt/system packages)

# macOS: Cache brew --prefix to avoid 0.8s delay on every shell startup
if [[ -z "$HOMEBREW_PREFIX" ]] && command -v brew >/dev/null 2>&1; then
  export HOMEBREW_PREFIX="$(brew --prefix)"
fi

# Try multiple installation locations in order of preference
if [[ -r "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]]; then
  # macOS Homebrew
  source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
  source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
elif [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
  # Raspberry Pi / Debian / Ubuntu (apt install fzf)
  source /usr/share/doc/fzf/examples/key-bindings.zsh
  source /usr/share/doc/fzf/examples/completion.zsh
elif [[ -r /usr/share/fzf/key-bindings.zsh ]]; then
  # Alternative Linux location
  source /usr/share/fzf/key-bindings.zsh
  source /usr/share/fzf/completion.zsh
fi

# --- Appearance ---
export FZF_DEFAULT_OPTS="
  --height 40%
  --layout=reverse
  --border
  --preview-window=right:60%
  --color=border:#d2aef5
  --no-separator
  --no-scrollbar
  --info=hidden
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
