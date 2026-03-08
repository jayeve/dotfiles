#!/usr/bin/env bash
# Consolidated Script Runner for Hammerspoon
# Displays all scripts from all configured categories in a single fzf picker

set -euo pipefail

# Add Homebrew to PATH
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

CONFIG_FILE="$HOME/.config/script-runner-hotkeys.json"

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
	echo "Error: Config file not found: $CONFIG_FILE"
	echo "Press Enter to exit..."
	read -r
	exit 1
fi

# Check if jq is available (for JSON parsing)
if ! command -v jq &>/dev/null; then
	echo "Error: jq not found. Install with: brew install jq"
	echo "Press Enter to exit..."
	read -r
	exit 1
fi

# Check if fzf is available
if ! command -v fzf &>/dev/null; then
	echo "Error: fzf not found. Install with: brew install fzf"
	echo "Press Enter to exit..."
	read -r
	exit 1
fi

# ANSI color codes for categories
COLOR_BLUE="\033[38;5;39m"         # Terminal
COLOR_ORANGE="\033[38;5;214m"      # Dotfiles
COLOR_DARK_ORANGE="\033[38;5;208m" # Cloudflare
COLOR_GREEN="\033[38;5;120m"       # Personal
COLOR_PURPLE="\033[38;5;141m"      # Kubernetes
COLOR_RED="\033[38;5;196m"         # SSH
RESET="\033[0m"

# Function to get color for a key
get_color() {
	case "$1" in
	t) echo "$COLOR_BLUE" ;;
	d) echo "$COLOR_ORANGE" ;;
	c) echo "$COLOR_DARK_ORANGE" ;;
	p) echo "$COLOR_GREEN" ;;
	k) echo "$COLOR_PURPLE" ;;
	s) echo "$COLOR_RED" ;;
	*) echo "" ;;
	esac
}

# Build script list with format: CATEGORY | script-name.sh<TAB>/full/path
script_list=""

# Read config and process each category
while IFS= read -r key; do
	name=$(jq -r ".[\"$key\"].name" "$CONFIG_FILE")
	path=$(jq -r ".[\"$key\"].path" "$CONFIG_FILE")

	# Expand tilde in path
	path="${path/#\~/$HOME}"

	# Skip if directory doesn't exist
	if [[ ! -d "$path" ]]; then
		continue
	fi

	# Get color for this category using the key (t, d, c, p, k, s)
	color=$(get_color "$key")

	# Find scripts in this directory
	if command -v fd &>/dev/null; then
		scripts=$(fd . "$path" --type f --type x 2>/dev/null || true)
	else
		scripts=$(find "$path" -type f \( -perm +111 -o -name "*.sh" -o -name "*.bash" -o -name "*.zsh" \) 2>/dev/null || true)
	fi

	# Process each script found
	while IFS= read -r fullpath; do
		[[ -z "$fullpath" ]] && continue

		# Get relative path for display
		relpath="${fullpath#$path/}"

		# Pad category name to 12 characters for alignment
		padded_category=$(printf "%-12s" "$name")

		# Build line with format: COLOR + CATEGORY | script-name + RESET + TAB + full-path
		line="${color}${padded_category}${RESET} | ${relpath}	${fullpath}"

		if [[ -n "$script_list" ]]; then
			script_list+=$'\n'
		fi
		script_list+="$line"
	done <<<"$scripts"

done < <(jq -r 'keys[]' "$CONFIG_FILE")

# Check if any scripts were found
if [[ -z "$script_list" ]]; then
	echo "No scripts found in any configured directories"
	echo "Press Enter to exit..."
	read -r
	exit 0
fi

# Sort the list by category, then by script name
sorted_list=$(echo -e "$script_list" | sort)

# Run fzf with preview
if command -v bat &>/dev/null; then
	# Extract full path from selected line (after TAB character)
	selected=$(echo -e "$sorted_list" | fzf \
		--height=100% \
		--layout=reverse \
		--border \
		--ansi \
		--prompt="All Scripts > " \
		--delimiter=$'\t' \
		--with-nth=1 \
		--preview 'bat --color=always --style=numbers,changes --line-range=:100 {2}' \
		--preview-window=down:40%:wrap \
		--header="ESC to cancel" ||
		true)
else
	selected=$(echo -e "$sorted_list" | fzf \
		--height=100% \
		--layout=reverse \
		--border \
		--ansi \
		--prompt="All Scripts > " \
		--delimiter=$'\t' \
		--with-nth=1 \
		--preview 'cat {2}' \
		--preview-window=down:40%:wrap \
		--header="ESC to cancel" ||
		true)
fi

# Extract full path from selection (after TAB)
if [[ -n "$selected" ]]; then
	# Get everything after the TAB character
	fullpath=$(echo "$selected" | cut -f2)

	# Get display name (before TAB) for user feedback
	display_name=$(echo "$selected" | cut -f1)

	echo ""
	echo "Executing: $display_name"
	echo "Path: $fullpath"
	echo "----------------------------------------"

	# Make sure it's executable
	if [[ ! -x "$fullpath" ]]; then
		chmod +x "$fullpath"
	fi

	# Execute the script
	"$fullpath"

	exit_code=$?
	echo "----------------------------------------"
	echo "Script exited with code: $exit_code"

	# Keep window open if there was an error
	if [[ $exit_code -ne 0 ]]; then
		echo ""
		echo "Press Enter to close..."
		read -r
	fi
fi
