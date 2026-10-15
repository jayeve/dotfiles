#!/bin/bash
# Snapshot tmux session/window/pane layout to ~/.tmux_snapshot.
# Scheduled every 10 minutes by:
#   ../../../launchd/Library/LaunchAgents/com.jayeve.tmux-snapshot.plist
# Later restored by ~/dotfiles.git/tmux-restore.sh (reads ~/.tmux_snapshot).

TMUX="/opt/homebrew/bin/tmux"
SNAPSHOT_FILE="$HOME/.tmux_snapshot"

# Only overwrite the snapshot when tmux actually returns pane data, so we
# never clobber a good snapshot just because the server isn't running yet.
snapshot=$("$TMUX" list-panes -a -F '#{session_name} #{window_index} #{pane_index} #{pane_current_path}' 2>/dev/null)

if [[ -n "$snapshot" ]]; then
	printf '%s\n' "$snapshot" >"$SNAPSHOT_FILE"
fi
