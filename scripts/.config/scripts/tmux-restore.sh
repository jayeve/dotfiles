#!/bin/bash
# tmux list-panes -a -F '#{session_name} #{window_index} #{pane_index} #{pane_current_path}' > ~/.tmux_snapshot

# Refuse to run from inside a tmux session; this script is meant to be
# invoked from outside tmux (e.g. on login) to restore a previous layout.
if [ -n "$TMUX" ]; then
    echo "tmux-restore.sh: refusing to run inside an active tmux session" >&2
    exit 1
fi

while read -r session win pane path; do
    # Create the session if it doesn't exist
    tmux has-session -t "$session" 2>/dev/null || tmux new-session -d -s "$session" -c "$path"
    # Create the window if it doesn't exist
    tmux select-window -t "$session:$win" 2>/dev/null || tmux new-window -t "$session:$win" -c "$path"
    # Recreate splits based on pane indices
    if [ "$pane" -gt 0 ]; then
        tmux split-window -t "$session:$win" -c "$path"
        tmux select-layout -t "$session:$win" tiled
    fi
done < ~/.tmux_snapshot
