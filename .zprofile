function source_if_exists() { [[ -s $1 ]] && source $1 }

# source_if_exists "$HOME/.zshrc"

if [[ "$(uname)" == "Darwin" ]] && [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
