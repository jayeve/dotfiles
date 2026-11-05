# emacs mode
# bindkey -e
bindkey -M viins '^P' up-line-or-history
bindkey -M viins '^N' down-line-or-history

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

source_if_exists "$HOME/.fzf.zsh"
source_if_exists "$HOME/.work_functions.zsh"
source_if_exists "$HOME/.zsh_aliases"
source_if_exists "$HOME/.zsh_hotkeys"

# fe [FUZZY PATTERN] - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
#   - Preview files with bat
fe() {
  local __files
  OLDIFS=$IFS
  IFS=$'\n' __files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0 --preview 'bat --color=always --style=numbers --line-range=:500 {}'))
  [[ -n "$__files" ]] && ${EDITOR:-nvim} "${__files[@]}" && IFS=$OLDIFS || IFS=$OLDIFS
}

# fdd [FUZZY PATTERN] - Fuzzy find and cd into a directory
#   - Searches all directories recursively from current location
fdd() {
  local __dir
  __dir=$(fd --type d --hidden --exclude .git | fzf +m -q "$1" --preview 'ls -la {}') && cd "$__dir"
  return 0
}

# yank git branch to clipboard
ygb() {
  local branch
  branch=$(git symbolic-ref --quiet --short HEAD 2>/dev/null || git rev-parse --short HEAD)
  printf "%s" "$branch" | pbcopy
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

# List tmux sessions attached/switched to in the last N hours (default 24), most recent first.
# Merges ~/.tmux_history (written by tmux hooks, survives reboots) with the live server's
# session_last_attached; sessions that no longer exist are marked "(closed)".
tmux-recent() {
  local hours=${1:-24}
  local cutoff=$(( $(date +%s) - hours * 3600 ))
  local hist=${TMUX_HISTORY_FILE:-$HOME/.tmux_history}
  {
    [[ -r $hist ]] && awk '{ print "H\t" $0 }' "$hist"
    tmux list-sessions -F "L	#{session_last_attached}	#{session_name}" 2>/dev/null
  } | awk -F'\t' -v c="$cutoff" '
      $1 == "L" { live[$3] = 1 }
      $2 ~ /^[0-9]+$/ && $2 >= c && $2 > last[$3] { last[$3] = $2 }
      END { for (s in last) printf "%s\t%s\t%s\n", last[s], s, (s in live) ? "" : "  (closed)" }
    ' \
    | sort -rn \
    | while IFS=$'\t' read -r ts name note; do
        printf '%s  %s%s\n' "$(date -r "$ts" '+%Y-%m-%d %H:%M:%S')" "$name" "$note"
      done
}

# Memory footprint (incl. compressed/swapped, same as Activity Monitor) per tmux session,
# summed over every process under each pane. Also reports orphaned `nvim --embed` servers.
tmux-mem() {
  awk -F'\t' '
    function tomb(s,  u, n) {
      sub(/[+-]$/, "", s); u = substr(s, length(s)); n = substr(s, 1, length(s) - 1) + 0
      if (u == "G") return n * 1024; if (u == "M") return n; if (u == "K") return n / 1024
      if (u == "B") return n / 1048576; return s / 1048576
    }
    function tree(p,  i, t) { t = mem[p]; for (i = 1; i <= nkids[p]; i++) t += tree(kid[p, i]); return t }
    FNR == 1 { file++ }
    file == 1 { split($0, f, " "); if (f[1] ~ /^[0-9]+$/) mem[f[1]] = tomb(f[2]); next }
    file == 2 { split($0, f, " "); kid[f[2], ++nkids[f[2]]] = f[1]
                if (f[2] == 1 && f[3] ~ /(^|\/)nvim$/ && f[4] == "--embed") orph[f[1]] = 1; next }
    file == 3 { sess[$1] += tree($2) }
    END {
      for (s in sess) printf "%8.1f MB  %s\n", sess[s], s | "sort -rn"
      close("sort -rn")
      for (p in orph) { om += mem[p]; oc++ }
      if (oc) printf "\n%8.1f MB  (%d orphaned nvim --embed, not in any session: run nvim-orphans-kill)\n", om, oc
    }
  ' <(top -l 1 -stats pid,mem 2>/dev/null) \
    <(ps -axo pid=,ppid=,args=) \
    <(tmux list-panes -a -F "#{session_name}	#{pane_pid}")
}

# Kill `nvim --embed` servers orphaned when their TUI died (reparented to launchd, no tty).
# They often ignore SIGTERM, so escalate to SIGKILL after a short wait.
nvim-orphans-kill() {
  local -a pids alive
  pids=(${(f)"$(ps -axo pid=,ppid=,tty=,args= | awk '$2 == 1 && $3 == "??" && $4 == "nvim" && $5 == "--embed" { print $1 }')"})
  if (( ! $#pids )); then
    echo "No orphaned nvim --embed processes"
    return 0
  fi
  echo "Killing $#pids orphaned nvim --embed: ${pids[*]}"
  kill $pids 2>/dev/null
  sleep 3
  alive=(${(f)"$(pgrep -P 1 -f '^nvim --embed')"})
  pids=(${pids:*alive})
  if (( $#pids )); then
    echo "$#pids ignored SIGTERM, sending SIGKILL"
    kill -9 $pids 2>/dev/null
  fi
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

# bindkey '^G' gch
# bindkey '^F' glprj

# kubectl completion (cached for faster startup)
if command -v kubectl &>/dev/null; then
  kubectl_completion_cache="$HOME/.cache/zsh/kubectl_completion.zsh"

  # Regenerate cache if kubectl binary is newer than cache
  if [[ ! -f "$kubectl_completion_cache" ]] || [[ "$(command -v kubectl)" -nt "$kubectl_completion_cache" ]]; then
    kubectl completion zsh > "$kubectl_completion_cache" 2>/dev/null
  fi

  [[ -f "$kubectl_completion_cache" ]] && source "$kubectl_completion_cache"
fi

# Load custom theme with git worktree support
source_if_exists "$DOTFILES_PATH/zsh/.j.zsh-theme"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/bin:$PATH"

# Fix SSL cert validation for JVM tools (coursier, sbt, metals) behind Cloudflare Zero Trust
export JAVA_TOOL_OPTIONS="-Djavax.net.ssl.trustStore=$HOME/OpenJDK/jdk-22.jdk/Contents/Home/lib/security/cacerts -Djavax.net.ssl.trustStorePassword=changeit"
# export PATH="/Users/jevans/.git-ai/bin:$PATH"
# export BORINGSSL_DIR=/Users/jevans/code/boringssl
