#!/usr/bin/env bash
# Audio Output Device Selector using fzf
# Lists all output audio devices and sets the selected one as default

set -euo pipefail

# Add Homebrew to PATH
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

# Check if we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
	echo "Error: This script only works on macOS"
	exit 1
fi

# Get current default output device
CURRENT_OUTPUT=$(osascript -e 'output volume of (get volume settings)' 2>/dev/null || echo "")

# Get list of all audio output devices using system_profiler
# This is more reliable than SwitchAudioSource for listing
DEVICES=$(system_profiler SPAudioDataType 2>/dev/null |
	grep -A 1 "Output Devices:" -A 100 |
	grep ":" |
	grep -v "Output Devices:" |
	sed 's/^[[:space:]]*//' |
	sed 's/:$//' || echo "")

# Alternative: Use SwitchAudioSource if installed (brew install switchaudio-osx)
if command -v SwitchAudioSource &>/dev/null; then
	DEVICES=$(SwitchAudioSource -a -t output)
	CURRENT=$(SwitchAudioSource -c -t output)

	# Format devices with current marker
	FORMATTED=""
	while IFS= read -r device; do
		if [[ "$device" == "$CURRENT" ]]; then
			FORMATTED+="● $device (current)\n"
		else
			FORMATTED+="  $device\n"
		fi
	done <<<"$DEVICES"

	# Use fzf to select device
  SELECTED=$(echo -e "$FORMATTED" | grep -Eiv "input|zoomaudiodevice|blackhole 2ch" | fzf \
		--height=100% \
		--layout=reverse \
		--border \
		--prompt="Select audio output device: " \
		--header="Current: $CURRENT | ESC to cancel" \
		--ansi \
		--no-preview ||
		true)

	if [[ -n "$SELECTED" ]]; then
		# Strip marker and "(current)" suffix
		DEVICE_NAME=$(echo "$SELECTED" | sed 's/^[●[:space:]]*//' | sed 's/ (current)$//')

		# Set as default output device
		SwitchAudioSource -s "$DEVICE_NAME" -t output

		echo ""
		echo "✓ Switched to: $DEVICE_NAME"
		sleep 0.5
	else
		echo "Cancelled"
	fi
else
	# Fallback: Use AppleScript method (limited functionality)
	echo "For better audio device switching, install SwitchAudioSource:"
	echo "  brew install switchaudio-osx"
	echo ""
	echo "Press Enter to continue..."
	read -r
fi
