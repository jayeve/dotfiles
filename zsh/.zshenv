. "$HOME/.cargo/env"
. "$HOME/.local/share/cloudflare-warp-certs/config.sh"

# Load local secrets (not tracked in git)
[ -f "$HOME/.zshenv.local" ] && . "$HOME/.zshenv.local"
