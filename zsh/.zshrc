# Load colors
autoload -Uz colors && colors

# setopt globstarshort

# History settings
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000
# append to history, don’t overwrite
setopt append_history

# write to history immediately after each command
setopt inc_append_history

# remove duplicate entries
setopt hist_ignore_dups hist_ignore_space

# share history across all sessions
setopt share_history

# optional: ignore commands starting with space
setopt hist_ignore_space

# Completion system (with caching, but faster than OMZ)
# Only regenerate compdump once per day for faster startup
autoload -Uz compinit
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.cache/zsh"
mkdir -p "$HOME/.cache/zsh"
if [[ -n "$HOME/.cache/zcompdump"(#qN.mh+24) ]]; then
  compinit -d "$HOME/.cache/zcompdump"
else
  compinit -C -d "$HOME/.cache/zcompdump"
fi

# Editor / pager
export EDITOR=nvim
export PAGER=less
export LESS='-F -g -i -M -R -S -w -X -z-4'

# load fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# PATH extension helper
extend_path() { [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH" }
extend_path "$HOME/.local/bin"
extend_path "$HOME/bin"

# Source helper for optional files
source_if_exists() { [[ -f "$1" ]] && source "$1" }

# Useful extras (optional) - cache zoxide init for faster startup
if (( $+commands[zoxide] )); then
  local zoxide_cache="$HOME/.cache/zsh/zoxide_init.zsh"
  # Regenerate cache if it doesn't exist or is older than 7 days
  [[ ! -f "$zoxide_cache" || -n "$zoxide_cache"(#qN.mw+1) ]] && {
    mkdir -p "${zoxide_cache:h}"
    zoxide init zsh > "$zoxide_cache" 2>/dev/null
  }
  source_if_exists "$zoxide_cache"
fi

# cross-platform clipboard
if which xclip > /dev/null; then
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
fi

source_if_exists "$HOME/.work_functions.zsh"
source_if_exists "$HOME/.zsh_aliases"
source_if_exists "$HOME/.zsh_hotkeys"

# fe [FUZZY PATTERN] - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
fe() {
  local __files
  OLDIFS=$IFS
  IFS=$'\n' __files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
  [[ -n "$__files" ]] && ${EDITOR:-nvim} "${__files[@]}" && IFS=$OLDIFS || IFS=$OLDIFS
}

# fd [FUZZY PATTERN] - Open the selected folder
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
fdd() {
  local __file
  local __dir
  __file=$(fzf +m -q "$1") && __dir=$(dirname "$__file") && cd "$__dir"
}

# Logic remains in the function for reliability
tm() {
  local s root

  # Get repo root (works for worktrees)
  root=$(git rev-parse --show-toplevel 2>/dev/null)

  if [[ -n "$root" ]]; then
    s=${root:t}
  else
    s=${PWD:t}
  fi

  # Strip trailing .git if present
  s=${s%.git}

  if [[ -n $TMUX && "$(tmux display-message -p '#S')" == "$s" ]]; then
    echo "Already in $s"
    return 0
  fi

  tmux new-session -Ad -s "$s" && {
    [[ -n $TMUX ]] && tmux switch-client -t "$s" || tmux attach-session -t "$s"
  }
}

gch () {
  git for-each-ref refs/heads \
    --sort=-committerdate \
    --format='%(refname:short)|%(committerdate:relative)|%(subject)' | \
  awk -F'|' '{
    printf "%-15s | \033[38;5;81m%-30s\033[0m | \033[38;5;108m(%s)\033[0m\n", $1, $3, $2
  }' | \
  fzf-tmux --ansi --border \
    --color='info:143,border:240,spinner:108,hl+:red' \
    --delimiter=' \| ' \
    --with-nth=1,2,3 | \
  sed 's/\x1b\[[0-9;]*m//g' | \
  awk -F' \\| ' '{print $1}' | \
  xargs -r git checkout
}

# Hammerspoon integration for shell status (optimized with caching)
# Cache Hammerspoon running state to avoid slow pgrep on every command
_hs_running_cache=""
_hs_cache_time=0

_is_hammerspoon_running() {
  local now=$(date +%s)
  # Cache for 5 seconds to avoid repeated pgrep calls (~267ms each!)
  if [[ -z "$_hs_cache_time" ]] || (( now - _hs_cache_time > 5 )); then
    if pgrep -x Hammerspoon >/dev/null 2>&1; then
      _hs_running_cache="yes"
    else
      _hs_running_cache="no"
    fi
    _hs_cache_time=$now
  fi
  [[ "$_hs_running_cache" == "yes" ]]
}

send_hs_status() {
  # If $TMUX is set, we are in tmux. Otherwise, we aren't.
  local tmux_state="NO_TMUX"
  [[ -n "$TMUX" ]] && tmux_state="IN_TMUX"

  local msg="$$|$1|$tmux_state"

  # Send to Hammerspoon via CLI (suppress errors for speed)
  hs -c "$(printf 'CheckInTmux(%q, %q, %q)' "$$" "active" "$([ -n "$TMUX" ] && echo true || echo false)")" 2>/dev/null
}

function _set_title() {
  # If in tmux, let tmux manage titles
  [[ -n "$TMUX" ]] && return
  # Otherwise set title to something useful (cwd)
  print -Pn "\e]0;%~\a"
}

# Hammerspoon shell status notifications (with caching to reduce lag)
precmd_functions+=(_set_title)
precmd() {
  # Only send status if Hammerspoon is running (uses 5-second cache)
  _is_hammerspoon_running && send_hs_status "IDLE"
}
preexec() {
  # Clear git cache if running a git command
  # Only send status if Hammerspoon is running (uses 5-second cache)
  _is_hammerspoon_running && send_hs_status "BUSY"
}

# opencode
export PATH=/Users/jevans/.opencode/bin:$PATH
# basic setup
# allow $(...) in PROMPT
setopt prompt_subst

# Copy the last executed command (previous history entry) to clipboard
alac_lastcmd_clip() {
  # fc -ln -1 prints the most recent history line
  local cmd
  cmd="$(fc -ln -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [[ -n "$cmd" ]] && printf %s "$cmd" | pbcopy
}

# Interactive hotkey reference with fzf
hotkeys() {
  local hotkey_file="$DOTFILES_PATH/HOTKEYS.md"

  if [[ ! -f "$hotkey_file" ]]; then
    echo "Error: Hotkey reference not found at $hotkey_file"
    return 1
  fi

  # Check for argument to determine mode
  if [[ "$1" == "full" ]] || [[ "$1" == "-f" ]]; then
    # Full document view
    if command -v bat &> /dev/null; then
      bat --paging=always --style=plain "$hotkey_file"
    else
      less "$hotkey_file"
    fi
  else
    # Interactive searchable mode using grep and sed (more portable than zsh regex)
    local temp_file=$(mktemp)
    local current_section=""

    # Use awk for more reliable parsing
    awk '
      /^## [^#]/ {
        section = $0
        gsub(/^## /, "", section)
        gsub(/ /, "_", section)
      }
      /^- \*\*.*\*\*.*-/ {
        line = $0
        gsub(/^- \*\*/, "", line)
        split(line, parts, /\*\*/)
        if (length(parts) >= 2) {
          hotkey = parts[1]
          desc = parts[2]
          gsub(/^ *- */, "", desc)
          printf "[%s] %s → %s\n", section, hotkey, desc
        }
      }
    ' "$hotkey_file" > "$temp_file"

    # Use fzf to search through hotkeys
    if [[ -s "$temp_file" ]]; then
      cat "$temp_file" | \
        fzf --ansi \
            --header="Search Hotkeys (Enter to view full doc, Esc to quit)" \
            --preview="echo {} | cut -d']' -f2- | sed 's/^[[:space:]]*//' | fold -w 80" \
            --preview-window=up:30%:wrap \
            --bind='enter:execute(bat --paging=always --style=plain '"$hotkey_file"')+abort' \
            --height=100%
    else
      echo "No hotkeys found. Showing full document..."
      if command -v bat &> /dev/null; then
        bat --paging=always --style=plain "$hotkey_file"
      else
        less "$hotkey_file"
      fi
    fi

    rm -f "$temp_file"
  fi
}


zle -N gch
zle -N glprj

bindkey '^G' gch
bindkey '^F' glprj

git_info() {

  # Exit if not inside a Git repository
  ! git rev-parse --is-inside-work-tree > /dev/null 2>&1 && return

  # Git branch/tag, or name-rev if on detached head
  local GIT_LOCATION=${$(git symbolic-ref -q HEAD || git name-rev --name-only --no-undefined --always HEAD)#(refs/heads/|tags/)}

  local cpu_name="j@cloudflare"
  local AHEAD="%{$fg[yellow]%}⇡NUM%{$reset_color%}"
  local BEHIND="%{$fg[cyan]%}⇣NUM%{$reset_color%}"
  local MERGING="%{$fg[magenta]%}%{$reset_color%}"
  local UNTRACKED="%{$fg[red]%}●%{$reset_color%}"
  local MODIFIED="%{$fg[red]%}●%{$reset_color%}"
  local STAGED="%{$fg[green]%}●%{$reset_color%}"

  local -a DIVERGENCES
  local -a FLAGS

  local NUM_AHEAD="$(git log --oneline @{u}.. 2> /dev/null | wc -l | tr -d ' ')"
  if [ "$NUM_AHEAD" -gt 0 ]; then
    DIVERGENCES+=( "${AHEAD//NUM/$NUM_AHEAD}" )
  fi

  local NUM_BEHIND="$(git log --oneline ..@{u} 2> /dev/null | wc -l | tr -d ' ')"
  if [ "$NUM_BEHIND" -gt 0 ]; then
    DIVERGENCES+=( "${BEHIND//NUM/$NUM_BEHIND}" )
  fi

  local GIT_DIR="$(git rev-parse --git-dir 2> /dev/null)"
  if [ -n $GIT_DIR ] && test -r $GIT_DIR/MERGE_HEAD; then
    FLAGS+=( "$MERGING" )
  fi

  if [[ -n $(git ls-files --other --exclude-standard 2> /dev/null) ]]; then
    FLAGS+=( "$UNTRACKED" )
  fi

  if ! git diff --quiet 2> /dev/null; then
    FLAGS+=( "$MODIFIED" )
  fi

  if ! git diff --cached --quiet 2> /dev/null; then
    FLAGS+=( "$STAGED" )
  fi

  local -a GIT_INFO
  [ -n "$GIT_STATUS" ] && GIT_INFO+=( "$GIT_STATUS" )
  [[ ${#DIVERGENCES[@]} -ne 0 ]] && GIT_INFO+=( "${(j::)DIVERGENCES}" )
  [[ ${#FLAGS[@]} -ne 0 ]] && GIT_INFO+=( "${(j::)FLAGS}" )
  GIT_INFO+=( "\033[38;5;15m$GIT_LOCATION%{$reset_color%}" )
  echo "$fg[red][${(j: :)GIT_INFO}$fg[red]]"
}
OS=$(uname -s)
OS_LOWER="${OS:l}"
# PROMPT: uses prompt escapes (%F{color}, %B/%b for bold, %~ for path, etc.)
PROMPT=$'%F{red}┌─%(?,,%F{red}[%F{red}%B✗%b%f%F{red}]─)[%F{cyan}%~%f%F{red}]-$(git_info)-[%F{cyan}%W-%@%F{red}]-[%F{green}jobs: %j%F{red}]
%F{red}└───[%B%F{green}$(whoami)@$OS_LOWER%F{red}]╼ %B%F{yellow}%(!.#.$)%b%f '

# PS2 (continuation prompt)
PS2=$' %F{green}|>%f '
export PATH="$HOME/.cargo/bin:$PATH"
