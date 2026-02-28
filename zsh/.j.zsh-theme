#!/usr/bin/env zsh

# Gruvbox + Lavender color scheme (matching tmux theme)
# - 237 (gray) - Brackets and borders (Gruvbox gray #3c3836)
# - 108 (aqua) - Path (Gruvbox aqua #8ec07c)
# - 140 (lavender) - Branch name and wt indicator (#9966cc close to #9b7fbf)
# - 183 (light lavender) - Time/date (#d2aef5)
# - 136 (gold) - Jobs count (#a17e1f)
# - 142 (green) - Username (Gruvbox green #b8bb26)
# - 220 (yellow) - Prompt symbol (Gruvbox yellow #fabd2f)
# - 167 (red) - Error and modified files (Gruvbox red #fb4934)

# Worktree indicator - shows wt if in a bare repo with .git suffix OR in a worktree
worktree_info() {
  # Check if we're in a bare repo
  if git rev-parse --is-bare-repository > /dev/null 2>&1 && [[ "$(git rev-parse --is-bare-repository 2>/dev/null)" == "true" ]]; then
    # Check if directory name ends with .git (worktree convention)
    if [[ "$(basename $(pwd))" == *.git ]]; then
      echo "%F{140}%B wt%b%f"
    fi
    return
  fi

  # Check if we're in a worktree
  ! git rev-parse --is-inside-work-tree > /dev/null 2>&1 && return

  local git_common_dir="$(git rev-parse --git-common-dir 2> /dev/null)"
  local git_dir="$(git rev-parse --git-dir 2> /dev/null)"

  # If git-common-dir differs from git-dir, we're in a worktree
  if [[ -n "$git_common_dir" ]] && [[ -n "$git_dir" ]] && [[ "$git_common_dir" != "$git_dir" ]]; then
    echo "%F{140}%B wt%b%f"
  fi
}

branch_info() {

  # Check if we're in a bare repo - if so, skip git info entirely
  if git rev-parse --is-bare-repository > /dev/null 2>&1 && [[ "$(git rev-parse --is-bare-repository 2>/dev/null)" == "true" ]]; then
    return
  fi

  # Exit if not inside a Git repository work tree
  ! git rev-parse --is-inside-work-tree > /dev/null 2>&1 && return

  # Git branch/tag, or name-rev if on detached head
  local GIT_LOCATION=${$(git symbolic-ref -q HEAD || git name-rev --name-only --no-undefined --always HEAD)#(refs/heads/|tags/)}

  local AHEAD="%F{220}⇡NUM%f"
  local BEHIND="%F{108}⇣NUM%f"
  local MERGING="%F{140}⚡%f"
  local UNTRACKED="%F{167}●%f"
  local MODIFIED="%F{167}●%f"
  local STAGED="%F{142}●%f"

  local -a DIVERGENCES
  local -a FLAGS

  # Try to use upstream first, otherwise fall back to default branch
  local NUM_AHEAD=0
  local NUM_BEHIND=0
  local CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  
  # Check if upstream is configured
  local UPSTREAM_REMOTE=$(git config --get branch.$CURRENT_BRANCH.remote 2>/dev/null)
  local UPSTREAM_MERGE=$(git config --get branch.$CURRENT_BRANCH.merge 2>/dev/null | sed 's@^refs/heads/@@')
  
  if [ -n "$UPSTREAM_REMOTE" ] && [ -n "$UPSTREAM_MERGE" ]; then
    # Upstream is configured, try to use it
    # First check if @{u} works (handles both regular repos and worktrees with remote tracking)
    if git rev-parse --abbrev-ref @{u} > /dev/null 2>&1; then
      # Use @{u} - works for regular repos and worktrees with refs/remotes
      NUM_AHEAD="$(git log --oneline @{u}.. 2> /dev/null | wc -l | tr -d ' ')"
      NUM_BEHIND="$(git log --oneline ..@{u} 2> /dev/null | wc -l | tr -d ' ')"
    else
      # @{u} doesn't work, likely a bare repo worktree without refs/remotes
      # Check if we're in a worktree (git-common-dir differs from git-dir)
      local git_dir="$(git rev-parse --git-dir 2>/dev/null)"
      local git_common_dir="$(git rev-parse --git-common-dir 2>/dev/null)"
      
      if [ -n "$git_dir" ] && [ -n "$git_common_dir" ] && [ "$git_dir" != "$git_common_dir" ]; then
        # We're in a worktree, compare against the branch in the bare repo
        if [ -f "$git_common_dir/refs/heads/$UPSTREAM_MERGE" ]; then
          NUM_AHEAD="$(git log --oneline $UPSTREAM_MERGE.. 2> /dev/null | wc -l | tr -d ' ')"
          NUM_BEHIND="$(git log --oneline ..$UPSTREAM_MERGE 2> /dev/null | wc -l | tr -d ' ')"
        fi
      fi
    fi
  else
    # No upstream configured, find default branch
    # First try origin/HEAD (works in regular repos)
    local DEFAULT_BRANCH="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')"
    local COMPARE_REF=""
    
    if [ -n "$DEFAULT_BRANCH" ] && git show-ref --verify --quiet "refs/remotes/origin/$DEFAULT_BRANCH"; then
      # Regular repo with origin/main or origin/master
      COMPARE_REF="origin/$DEFAULT_BRANCH"
    else
      # Worktree or bare repo - try main/master directly in refs/heads
      if git show-ref --verify --quiet refs/heads/main; then
        COMPARE_REF="main"
      elif git show-ref --verify --quiet refs/heads/master; then
        COMPARE_REF="master"
      fi
    fi
    
    if [ -n "$COMPARE_REF" ]; then
      NUM_AHEAD="$(git log --oneline $COMPARE_REF.. 2> /dev/null | wc -l | tr -d ' ')"
      NUM_BEHIND="$(git log --oneline ..$COMPARE_REF 2> /dev/null | wc -l | tr -d ' ')"
    fi
  fi

  if [ "$NUM_AHEAD" -gt 0 ]; then
    DIVERGENCES+=( "${AHEAD//NUM/$NUM_AHEAD}" )
  fi

  if [ "$NUM_BEHIND" -gt 0 ]; then
    DIVERGENCES+=( "${BEHIND//NUM/$NUM_BEHIND}" )
  fi

  if [ -n "$GIT_DIR" ] && test -r "$GIT_DIR/MERGE_HEAD"; then
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
  GIT_INFO+=( "%F{140}%B $GIT_LOCATION%b%f" )
  echo "${(j: :)GIT_INFO}"
}

# Combined git and worktree info in single brackets
git_info() {
  local wt_info="$(worktree_info)"
  local branch_info_str="$(branch_info)"

  # If we have either worktree or git info, wrap in brackets
  if [[ -n "$wt_info" || -n "$branch_info_str" ]]; then
    echo -n "%F{237}-["
    [[ -n "$wt_info" ]] && echo -n "$wt_info"
    [[ -n "$wt_info" && -n "$branch_info_str" ]] && echo -n " "
    [[ -n "$branch_info_str" ]] && echo -n "$branch_info_str"
    echo "%F{237}]%f"
  fi
}

PROMPT=$'%F{237}┌─%(?,,%F{237}[%F{167}%B✗%b%f%F{237}]─)[%F{108}%~%f%F{237}]$(git_info)
%F{237}└───[%F{136}%B%n%b%f%F{237}]╼ %F{136}%B%(!.#.$)%b%f '
PS2=$' %F{142}|>%f '
