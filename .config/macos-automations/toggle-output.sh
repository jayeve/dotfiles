#!/bin/bash

# Get current audio output device
current=$(/opt/homebrew/bin/SwitchAudioSource -c -t output)

# Toggle between the two devices
if [[ "$current" == "MacBook Pro Speakers" ]]; then
	/opt/homebrew/bin/SwitchAudioSource -s "output_screen_recording_built_in_speakers"
	echo "Switched to: output_screen_recording_built_in_speakers"
elif [[ "$current" == "output_screen_recording_built_in_speakers" ]]; then
	/opt/homebrew/bin/SwitchAudioSource -s "MacBook Pro Speakers"
	echo "Switched to: MacBook Pro Speakers"
else
	# Default to MacBook Pro Speakers if currently on a different device
	/opt/homebrew/bin/SwitchAudioSource -s "MacBook Pro Speakers"
	echo "Switched to: MacBook Pro Speakers (from $current)"
fi
