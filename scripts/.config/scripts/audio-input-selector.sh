#!/usr/bin/env bash
# Audio Input Device Selector using fzf
# Lists all input audio devices and sets the selected one as default

set -euo pipefail

# Add Homebrew to PATH
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

# Check if we're on macOS
if [[ "$(uname)" != "Darwin" ]]; then
	echo "Error: This script only works on macOS"
	exit 1
fi

# Check if SwitchAudioSource is installed
if command -v SwitchAudioSource &>/dev/null; then
	DEVICES=$(SwitchAudioSource -a -t input)
	CURRENT=$(SwitchAudioSource -c -t input)

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
	SELECTED=$(echo -e "$FORMATTED" | fzf \
		--height=100% \
		--layout=reverse \
		--border \
		--prompt="Select audio input device: " \
		--header="Current: $CURRENT | ESC to cancel" \
		--ansi \
		--no-preview ||
		true)

	if [[ -n "$SELECTED" ]]; then
		# Strip marker and "(current)" suffix
		DEVICE_NAME=$(echo "$SELECTED" | sed 's/^[●[:space:]]*//' | sed 's/ (current)$//')

		# Set as default input device
		SwitchAudioSource -s "$DEVICE_NAME" -t input

		echo ""
		echo "✓ Switched to: $DEVICE_NAME"
		sleep 0.5
	else
		echo "Cancelled"
	fi
else
	echo "Error: SwitchAudioSource not found"
	echo ""
	echo "Install with:"
	echo "  brew install switchaudio-osx"
	echo ""
	echo "Press Enter to exit..."
	read -r
	exit 1
fi
