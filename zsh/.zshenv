[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -f "$HOME/.local/share/cloudflare-warp-certs/config.sh" ] && . "$HOME/.local/share/cloudflare-warp-certs/config.sh"

# Dotfiles location (master worktree of bare git checkout)
export DOTFILES_PATH="$HOME/dotfiles.git/master"

# Load local secrets (not tracked in git)
[ -f "$HOME/.zshenv.local" ] && . "$HOME/.zshenv.local"
