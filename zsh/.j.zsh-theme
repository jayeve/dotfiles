#!/usr/bin/env zsh

# Worktree indicator - shows [wt] if in a bare repo with worktrees OR in a worktree
worktree_info() {
  # Lavender color matching tmux theme (#9b7fbf)
  local LAVENDER="\033[38;2;155;127;191m"

  # Check if we're in a bare repo
  if git rev-parse --is-bare-repository > /dev/null 2>&1 && [[ "$(git rev-parse --is-bare-repository 2>/dev/null)" == "true" ]]; then
    # Check if this bare repo has worktrees
    local git_dir="$(git rev-parse --git-dir 2> /dev/null)"
    if [[ -d "$git_dir/worktrees" ]]; then
      echo "%{$fg[red]%}-[%{${LAVENDER}%}%B wt%b%{$reset_color%}%{$fg[red]%}]%{$reset_color%}%{$fg[red]%}"
    fi
    return
  fi

  # Check if we're in a worktree
  ! git rev-parse --is-inside-work-tree > /dev/null 2>&1 && return

  local git_common_dir="$(git rev-parse --git-common-dir 2> /dev/null)"
  local git_dir="$(git rev-parse --git-dir 2> /dev/null)"

  # If git-common-dir differs from git-dir, we're in a worktree
  if [[ -n "$git_common_dir" ]] && [[ -n "$git_dir" ]] && [[ "$git_common_dir" != "$git_dir" ]]; then
    echo "%{$fg[red]%}-[%{${LAVENDER}%}%B wt%b%{$reset_color%}%{$fg[red]%}]%{$reset_color%}%{$fg[red]%}"
  fi
}

git_info() {

  # Check if we're in a bare repo - if so, skip git info entirely
  if git rev-parse --is-bare-repository > /dev/null 2>&1 && [[ "$(git rev-parse --is-bare-repository 2>/dev/null)" == "true" ]]; then
    return
  fi

  # Exit if not inside a Git repository work tree
  ! git rev-parse --is-inside-work-tree > /dev/null 2>&1 && return

  # Git branch/tag, or name-rev if on detached head
  local GIT_LOCATION=${$(git symbolic-ref -q HEAD || git name-rev --name-only --no-undefined --always HEAD)#(refs/heads/|tags/)}

  local AHEAD="%{$fg[yellow]%}⇡NUM%{$reset_color%}"
  local BEHIND="%{$fg[cyan]%}⇣NUM%{$reset_color%}"
  local MERGING="%{$fg[magenta]%}⚡%{$reset_color%}"
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

  # Lavender color matching tmux theme (#9b7fbf)
  local LAVENDER="\033[38;2;155;127;191m"

  local -a GIT_INFO
  [ -n "$GIT_STATUS" ] && GIT_INFO+=( "$GIT_STATUS" )
  [[ ${#DIVERGENCES[@]} -ne 0 ]] && GIT_INFO+=( "${(j::)DIVERGENCES}" )
  [[ ${#FLAGS[@]} -ne 0 ]] && GIT_INFO+=( "${(j::)FLAGS}" )
  GIT_INFO+=( "${LAVENDER} %B$GIT_LOCATION%b%{$reset_color%}" )
  echo "$fg[red]-%{$reset_color%}$fg[red][${(j: :)GIT_INFO}$fg[red]]"
}

PROMPT=$'%{$fg[red]%}┌─%(?,,%{$fg[red]%}[%{$fg_bold[red]%}✗%{$reset_color%}%{$fg[red]%}]─)[%{$fg[cyan]%}%~%{$reset_color%}%{$fg[red]%}]%{$(worktree_info)%}%{$(git_info)%}-[$fg[cyan]%W-%@$fg[red]]-[$fg[green]jobs: %j$fg[red]]
%{$fg[red]%}└───[%{$fg_bold[green]%}%n%{$reset_color%}%{$fg[red]%}]╼ %{$fg_bold[yellow]%}%(!.#.$)%{$reset_color%} '
PS2=$' %{$fg[green]%}|>%{$reset_color%} '
