#!/bin/bash
# Append "<epoch>\t<session>" to ~/.tmux_history whenever a client attaches to or
# switches sessions (called from tmux hooks). Persists across reboots so
# `tmux-recent` can report sessions viewed before the tmux server restarted.

session=$1
[ -z "$session" ] && exit 0

log="${TMUX_HISTORY_FILE:-$HOME/.tmux_history}"
max_lines=20000

printf '%s\t%s\n' "$(date +%s)" "$session" >> "$log"

# Keep the log bounded: once it exceeds max_lines, keep the newest half.
if [ "$(wc -l < "$log")" -gt "$max_lines" ]; then
    tail -n $((max_lines / 2)) "$log" > "$log.tmp" && mv "$log.tmp" "$log"
fi
