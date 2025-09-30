# Load colors
autoload -Uz colors && colors

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
autoload -Uz compinit
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.cache/zsh"
mkdir -p "$HOME/.cache/zsh"
compinit -d "$HOME/.cache/zcompdump"

# Editor / pager
export EDITOR=nvim
export PAGER=less
export LESS='-F -g -i -M -R -S -w -X -z-4'

# PATH extension helper
extend_path() { [[ ":$PATH:" != *":$1:"* ]] && PATH="$1:$PATH" }
extend_path "$HOME/.local/bin"
extend_path "$HOME/bin"

# Aliases
alias ll='ls -lh'
alias la='ls -lha'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'

# Useful extras (optional)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# cross-platform clipboard
if which xclip > /dev/null; then
  alias pbcopy='xclip -selection clipboard'
  alias pbpaste='xclip -selection clipboard -o'
fi

source_if_exists "$HOME/.work_functions.zsh"
source_if_exists "$HOME/.zsh_aliases"

# fe [FUZZY PATTERN] - Open the selected file with the default editor
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
fe() {
  local __files
  OLDIFS=$IFS
  IFS=$'\n' __files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
  [[ -n "$__files" ]] && ${EDITOR:-vim} "${__files[@]}" && IFS=$OLDIFS || IFS=$OLDIFS
}

# fd [FUZZY PATTERN] - Open the selected folder
#   - Bypass fuzzy finder if there's only one match (--select-1)
#   - Exit if there's no match (--exit-0)
fdd() {
  local __file
  local __dir
  __file=$(fzf +m -q "$1") && __dir=$(dirname "$__file") && cd "$__dir"
}

function ff {
  result=$(rg --ignore-case --color=always --line-number --no-heading "$@" |
    fzf --ansi \
        --color 'hl:-1:underline,hl+:-1:underline:reverse' \
        --delimiter ':' \
        --preview "bat --color=always {1} --theme='Solarized (light)' --highlight-line {2}" \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3')
  file=${result%%:*}
  linenumber=$(echo "${result}" | cut -d: -f2)
  if [[ -n "$file" ]]; then
          $EDITOR +"${linenumber}" "$file"
  fi
}

function tm() {
  current_directory=$(basename "$PWD")
  # check if we're currently in a TMUX session
  if [[ -n $TMUX ]]; then
    current_session=$(tmux display-message -p '#S')
    echo "current session" $current_session
    if [[ "$current_session" == "$current_directory" ]]; then
      echo "No-op"
      return
    fi
  fi
  echo "checking for session" $current_directory
  tmux has-session -t $current_directory 2>/dev/null && tmux attach-session -t $current_directory || tmux new-session -d -s $current_directory
  # if we get to this line, we must not have switched sessions
  tmux switch-client -t $current_directory
}

gch () {
  git recent | \
    fzf-tmux --ansi --border \
      --color='info:143,border:240,spinner:108,hl+:red' \
      --delimiter ' | ' | \
    sed 's/^[ \t*]*//' | \
    awk '{print $1}' | \
    xargs git checkout
}

# basic setup
# allow $(...) in PROMPT
setopt prompt_subst

# git_info: command substitution will be evaluated when prompt is shown
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
