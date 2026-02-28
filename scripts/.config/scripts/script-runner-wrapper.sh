#!/usr/bin/env bash
# Script Runner wrapper for Hammerspoon
# Displays fzf selector for scripts in a directory and executes the selected one

set -euo pipefail

# Add Homebrew to PATH (needed when launched directly without shell login)
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

SCRIPT_DIR="${1:-$HOME/scripts}"
SCRIPT_NAME="${2:-Scripts}"
SCRIPT_DESC="${3:-}"

# Build prompt with name and description
if [[ -n "$SCRIPT_DESC" ]]; then
	PROMPT_TEXT="$SCRIPT_NAME - $SCRIPT_DESC > "
else
	PROMPT_TEXT="$SCRIPT_NAME > "
fi

# Ensure the directory exists
if [[ ! -d "$SCRIPT_DIR" ]]; then
	echo "Error: Directory '$SCRIPT_DIR' does not exist"
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

# Find scripts using fd (fast) or find (fallback)
if command -v fd &>/dev/null; then
	# fd: find all executable files and shell scripts
	scripts=$(fd . "$SCRIPT_DIR" --type f --type x 2>/dev/null || true)
else
	# fallback to find
	scripts=$(find "$SCRIPT_DIR" -type f \( -perm +111 -o -name "*.sh" -o -name "*.bash" -o -name "*.zsh" \) 2>/dev/null || true)
fi

# Check if any scripts were found
if [[ -z "$scripts" ]]; then
	echo "No scripts found in '$SCRIPT_DIR'"
	echo "Create executable scripts or .sh files in this directory"
	echo "Press Enter to exit..."
	read -r
	exit 0
fi

# Build list of relative paths and full paths (bash 3.2 compatible)
# We'll use line numbers to map between them
rel_paths=()
full_paths=()

while IFS= read -r fullpath; do
	# Get path relative to SCRIPT_DIR
	relpath="${fullpath#$SCRIPT_DIR/}"
	rel_paths+=("$relpath")
	full_paths+=("$fullpath")
done <<<"$scripts"

# Create display list (sorted)
display_list=$(printf '%s\n' "${rel_paths[@]}" | sort)

# Run fzf selector with preview
# Show description in prompt line, list at top, preview below
if command -v bat &>/dev/null; then
	# Use bat for syntax-highlighted preview
	selected_rel=$(echo "$display_list" | fzf \
		--height=100% \
		--layout=reverse \
		--border \
		--prompt="$PROMPT_TEXT" \
		--preview "bat --color=always --style=numbers,changes --line-range=:100 '$SCRIPT_DIR/{}'" \
		--preview-window=down:40%:wrap \
		--header="Directory: $SCRIPT_DIR | ESC to cancel" ||
		true)
else
	# Fallback to cat for preview
	selected_rel=$(echo "$display_list" | fzf \
		--height=100% \
		--layout=reverse \
		--border \
		--prompt="$PROMPT_TEXT" \
		--preview "cat '$SCRIPT_DIR/{}'" \
		--preview-window=down:40%:wrap \
		--header="Directory: $SCRIPT_DIR | ESC to cancel" ||
		true)
fi

# Find full path for selected relative path
if [[ -n "$selected_rel" ]]; then
	selected=""
	for i in "${!rel_paths[@]}"; do
		if [[ "${rel_paths[$i]}" == "$selected_rel" ]]; then
			selected="${full_paths[$i]}"
			break
		fi
	done

	if [[ -z "$selected" ]]; then
		echo "Error: Could not find full path for selected script"
		exit 1
	fi

	echo ""
	echo "Executing: $selected_rel"
	echo "----------------------------------------"

	# Make sure it's executable
	if [[ ! -x "$selected" ]]; then
		chmod +x "$selected"
	fi

	# Execute the script
	"$selected"

	exit_code=$?
	echo "----------------------------------------"
	echo "Script exited with code: $exit_code"
fi

# Get full path from selected relative path
if [[ -n "$selected_rel" ]]; then
	selected="${script_map[$selected_rel]}"

	echo ""
	echo "Executing: $selected_rel"
	echo "----------------------------------------"

	# Make sure it's executable
	if [[ ! -x "$selected" ]]; then
		chmod +x "$selected"
	fi

	# Execute the script
	"$selected"

	exit_code=$?
	echo "----------------------------------------"
	echo "Script exited with code: $exit_code"
fi

# Window will auto-close on exit (no need to wait)
