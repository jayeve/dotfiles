#!/bin/zsh

# Cache file to reduce ipconfig calls
CACHE_FILE="/tmp/tmux_network_cache"
CACHE_TTL=5 # seconds

# inspiration: https://github.com/catppuccin/tmux/issues/90#issuecomment-1961298007
get_current_network_text() {
	if [[ "$(uname)" == "Darwin" ]]; then
		# Check if cache exists and is recent
		if [[ -f "$CACHE_FILE" ]]; then
			local cache_age=$(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || echo 0)))
			if ((cache_age < CACHE_TTL)); then
				cat "$CACHE_FILE"
				return
			fi
		fi

		# current_network="$(networksetup -getairportnetwork en0 | awk -F: '{gsub(/^ *| *$/, "", $2); print $2}')"
		current_network="$(ipconfig getsummary en0 | awk -F ' SSID : ' '/ SSID : / {print $2}')"
		if [[ -z $current_network ]]; then
			echo 'disconnected' | tee "$CACHE_FILE"
		else
			echo "$current_network" | tee "$CACHE_FILE"
		fi
	else
		echo "ERR: Not OSX"
	fi
}

get_current_network_text
