#!/usr/bin/env zsh

# ---------- JIRA OPEN ----------
jopen() {
  if [[ $# -ne 1 ]]; then
    echo "Usage: jopen CR-958178"
    echo "This attempts to open the URL https://jira.cfdata.org/browse/CR-958178"
    return 1
  fi

  local url="https://jira.cfdata.org/browse/$1"
  echo "Opening $url"
  open "$url"
}

# ---------- FUZZY FILE OPEN ----------
ff() {
  local result file linenumber
  result=$(rg --ignore-case --color=always --line-number --no-heading "$@" |
           fzf --ansi \
               --color 'hl:-1:underline,hl+:-1:underline:reverse' \
               --delimiter ':' \
               --preview "bat --color=always {1} --theme='Solarized (light)' --highlight-line {2}" \
               --preview-window 'up,60%,border-bottom,+{2}+3/3,~3')
  file=${result%%:*}
  linenumber=${result#*:}
  linenumber=${linenumber%%:*}

  [[ -n "$file" ]] && ${EDITOR:-vim} +"$linenumber" "$file"
}

# ---------- PROJECT HELPER ----------
prj_helper() {
  local starting_dir=$PWD
  local base=$HOME/cloudflare
  local team=$1
  local project=$2
  local team_dir=$base/$team
  local project_dir=$team_dir/$project
  local repo_url="ssh://git@bitbucket.cfdata.org:7999/$team/$project.git"

  [[ ! -d "$base" ]] && mkdir -p "$base"

  if [[ ! -d "$project_dir" ]]; then
    if git ls-remote "$repo_url" &>/dev/null; then
      [[ ! -d "$team_dir" ]] && mkdir -p "$team_dir"
      echo "Cloning $repo_url into $project_dir"
      git clone "$repo_url" "$project_dir"
    else
      echo "ERROR: project $repo_url does not exist in Bitbucket"
      return 1
    fi
  fi

  if [[ -z $TMUX ]] && ! pgrep -x tmux &>/dev/null; then
    tmux new-session -s "$project" -c "$project_dir"
    return 0
  fi

  if ! tmux has-session -t "$project" 2>/dev/null; then
    tmux new-session -d -s "$project" -c "$project_dir"
  fi

  if [[ -z $TMUX ]]; then
    tmux attach-session -t "$project" -c "$project_dir"
  else
    tmux switch-client -t "$project"
  fi

  cd "$starting_dir"
}

# ---------- PROJECT WRAPPER ----------
prj() {
  if [[ $# -ne 2 ]]; then
    echo "Usage: prj TEAM PROJECT"
    return 1
  fi
  prj_helper "$1" "$2"
}

# ---------- Zsh completion for prj ----------
_prj() {
  local cur opts
  cur="${words[CURRENT]}"
  opts=($(ls $HOME/cloudflare))
  compadd -a opts
}
compdef _prj prj

# ---------- DEV SESSION ----------
dev() {
  prj cloudflare "$1"
  tmux new-session -d
  tmux split-window -h
  tmux split-window -v
  tmux -2 attach-session -d
}

# ---------- KILL PROCESS ----------
kp() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m --header='[kill:process]' | awk '{print $2}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill -${1:-9} && kp
}

# ---------- PROXY CONTROL ----------
enable_sfo_dog_proxy() {
  sudo warp-cli tunnel endpoint set '162.159.204.1:2408' &>/dev/null
  warp-cli tunnel rotate-keys &>/dev/null
  sleep 1
  curl -s https://cloudflare.com/cdn-cgi/trace | grep '^colo=\|^sliver=\|^fl='
}

disable_sfo_dog_proxy() {
  sudo warp-cli tunnel endpoint reset &>/dev/null
  sleep 1
  curl -s https://cloudflare.com/cdn-cgi/trace | grep '^colo=\|^sliver=\|^fl='
}

# ---------- ENV VARS ----------
export JAVA_HOME=$HOME/OpenJDK/jdk-22.jdk/Contents/Home
export PATH=$JAVA_HOME/bin:$PATH

# ---------- TEMPORAL CLI COMPLETION ----------
# Lazy-load temporal completions for faster shell startup
if command -v temporal >/dev/null 2>&1; then
  # Cache completions to avoid running temporal on every shell startup
  local temporal_completion_cache="$HOME/.cache/zsh/temporal_completion.zsh"

  # Regenerate cache if it doesn't exist or is older than 7 days
  if [[ ! -f "$temporal_completion_cache" ]] || [[ -n "$temporal_completion_cache"(#qN.mw+1) ]]; then
    mkdir -p "$HOME/.cache/zsh"
    temporal completion zsh > "$temporal_completion_cache" 2>/dev/null
  fi

  # Source cached completions
  [[ -f "$temporal_completion_cache" ]] && source "$temporal_completion_cache"
fi

curl-tracing() {
  local response=$(cloudflared access curl https://tracegen.cfperf.net -s -XPOST)
  echo "Signed trace: $(jq -r .signed_trace <<<${response})"
  curl -sH "cf-trace-id:$(jq -r .signed_trace <<<${response})" "$@"
  echo "Jaeger UI: https://tracing.cfdata.org/trace/$(jq -r .trace_id <<<${response})"
}

# ---------- GITLAB PROJECT SELECTOR ----------
# SSH-based GitLab project selector with fzf (no token required)
# Uses local cache and SSH keys for authentication

glprj() {
  local base=$HOME/cloudflare
  local gitlab_url="git@gitlab.cfdata.org"
  local cache_file="$HOME/.gitlab-projects-cache"

  # Check if cache exists
  if [[ ! -f "$cache_file" ]]; then
    echo "Error: Project cache not found at $cache_file"
    echo "Run 'glprj-init' to create it, or manually create the file with project paths."
    echo ""
    echo "Example format (one per line):"
    echo "  cloudflare/fl/fl2"
    echo "  cloudflare/workers/workers-sdk"
    return 1
  fi

  # Build list combining local (with marker) and remote projects
  local projects_list
  projects_list=$(cat "$cache_file" | while IFS= read -r project_path; do
    local check_path="$project_path"
    [[ "$project_path" == "cloudflare/"* ]] && check_path="${project_path#cloudflare/}"

    if [[ -d "$base/$check_path" ]]; then
      echo "LOCAL  $project_path"
    else
      echo "REMOTE $project_path"
    fi
  done)

  local selected
  selected=$(echo "$projects_list" | \
    fzf --height 40% --reverse --border \
        --prompt "GitLab Project (LOCAL/REMOTE): " \
        --preview 'echo {2}' \
        --preview-window right:40% \
        --header 'LOCAL = already cloned | REMOTE = will clone')

  if [[ -z "$selected" ]]; then
    return 0
  fi

  # Extract just the project path (remove LOCAL/REMOTE prefix)
  local full_path=$(echo "$selected" | awk '{print $2}')
  local project=$(basename "$full_path")
  
  # For cloudflare/* projects, strip the cloudflare/ prefix since base is already ~/cloudflare
  local relative_path="$full_path"
  if [[ "$full_path" == "cloudflare/"* ]]; then
    relative_path="${full_path#cloudflare/}"
  fi
  
  local project_dir="$base/$relative_path"

  # Clone if doesn't exist locally
  if [[ ! -d "$project_dir" ]]; then
    mkdir -p "$(dirname "$project_dir")"
    echo "Cloning ${gitlab_url}:${full_path}.git"
    git clone "${gitlab_url}:${full_path}.git" "$project_dir" || return 1
  fi

  # Open in tmux
  local starting_dir=$PWD

  if [[ -z $TMUX ]] && ! pgrep -x tmux &>/dev/null; then
    tmux new-session -s "$project" -c "$project_dir"
    return 0
  fi

  if ! tmux has-session -t "$project" 2>/dev/null; then
    tmux new-session -d -s "$project" -c "$project_dir"
  fi

  if [[ -z $TMUX ]]; then
    tmux attach-session -t "$project" -c "$project_dir"
  else
    tmux switch-client -t "$project"
  fi

  cd "$starting_dir"
}

# Bare repo version of glprj for git-worktree workflow
glprj-bare() {
  local base=$HOME/cloudflare
  local gitlab_url="git@gitlab.cfdata.org"
  local cache_file="$HOME/.gitlab-projects-cache"

  # Check if cache exists
  if [[ ! -f "$cache_file" ]]; then
    echo "Error: Project cache not found at $cache_file"
    echo "Run 'glprj-init' to create it, or manually create the file with project paths."
    return 1
  fi

  # Build list combining local (with marker) and remote projects
  local projects_list
  projects_list=$(cat "$cache_file" | while IFS= read -r project_path; do
    local check_path="$project_path"
    [[ "$project_path" == "cloudflare/"* ]] && check_path="${project_path#cloudflare/}"

    if [[ -d "$base/$check_path.git" ]]; then
      echo "LOCAL  $project_path"
    else
      echo "REMOTE $project_path"
    fi
  done)

  local selected
  selected=$(echo "$projects_list" | \
    fzf --height 40% --reverse --border \
        --prompt "GitLab Project (bare): " \
        --preview 'echo {2}' \
        --preview-window right:40% \
        --header 'LOCAL = already cloned | REMOTE = will clone as bare')

  if [[ -z "$selected" ]]; then
    return 0
  fi

  # Extract just the project path (remove LOCAL/REMOTE prefix)
  local full_path=$(echo "$selected" | awk '{print $2}')
  local project=$(basename "$full_path")
  
  # For cloudflare/* projects, strip the cloudflare/ prefix since base is already ~/cloudflare
  local relative_path="$full_path"
  if [[ "$full_path" == "cloudflare/"* ]]; then
    relative_path="${full_path#cloudflare/}"
  fi
  
  local bare_dir="$base/$relative_path.git"

  # Clone as bare if doesn't exist locally
  if [[ ! -d "$bare_dir" ]]; then
    mkdir -p "$(dirname "$bare_dir")"
    echo "Cloning ${gitlab_url}:${full_path}.git as bare repo"
    git clone --bare "${gitlab_url}:${full_path}.git" "$bare_dir" || return 1
    echo "Bare repo created at: $bare_dir"
    echo "Use 'git worktree add' to create working directories"
  fi

  # Check if there are any worktrees
  local worktrees
  worktrees=$(cd "$bare_dir" && git worktree list --porcelain 2>/dev/null | grep "^worktree " | sed 's/^worktree //')
  
  if [[ -z "$worktrees" ]]; then
    echo "No worktrees found. Create one with:"
    echo "  cd $bare_dir && git worktree add ../$(basename "$bare_dir" .git)/main main"
    return 0
  fi

  # Select or create worktree
  local worktree_choice
  worktree_choice=$(echo "$worktrees\n+ Create new worktree" | \
    fzf --height 40% --reverse --border \
        --prompt "Select worktree: " \
        --header 'Choose existing worktree or create new one')

  if [[ -z "$worktree_choice" ]]; then
    return 0
  fi

  local target_dir
  if [[ "$worktree_choice" == "+ Create new worktree" ]]; then
    # Prompt for branch name
    echo -n "Enter branch name for new worktree: "
    read branch_name
    if [[ -z "$branch_name" ]]; then
      echo "No branch name provided, aborting"
      return 1
    fi
    
    target_dir="$base/$relative_path/$branch_name"
    mkdir -p "$(dirname "$target_dir")"
    
    (cd "$bare_dir" && git worktree add "$target_dir" "$branch_name") || return 1
    echo "Created worktree: $target_dir"
  else
    target_dir="$worktree_choice"
  fi

  # Open in tmux
  local session_name="${project}-$(basename "$target_dir")"
  local starting_dir=$PWD

  if [[ -z $TMUX ]] && ! pgrep -x tmux &>/dev/null; then
    tmux new-session -s "$session_name" -c "$target_dir"
    return 0
  fi

  if ! tmux has-session -t "$session_name" 2>/dev/null; then
    tmux new-session -d -s "$session_name" -c "$target_dir"
  fi

  if [[ -z $TMUX ]]; then
    tmux attach-session -t "$session_name" -c "$target_dir"
  else
    tmux switch-client -t "$session_name"
  fi

  cd "$starting_dir"
}

# Initialize cache from local repos
glprj-init() {
  local base=$HOME/cloudflare
  local cache_file="$HOME/.gitlab-projects-cache"

  echo "Scanning for local GitLab repos in $base..."

  if [[ ! -d "$base" ]]; then
    echo "Warning: $base doesn't exist yet."
    echo "Creating empty cache file. You can manually add project paths to:"
    echo "  $cache_file"
    touch "$cache_file"
    return 0
  fi

  # Find all git repos under cloudflare/
  find "$base" -name .git -type d 2>/dev/null | while read gitdir; do
    local project_dir=$(dirname "$gitdir")
    local relative_path="${project_dir#$base/}"
    echo "$relative_path"
  done | sort -u > "$cache_file"

  local count=$(wc -l < "$cache_file")
  echo "Found $count local projects and cached them to $cache_file"
  echo ""
  echo "To add more projects, edit the file and add paths like:"
  echo "  cloudflare/fl/fl2"
  echo "  cloudflare/workers/workers-sdk"
}

# Search GitLab and add matching projects to cache
glprj-sync() {
  local cache_file="$HOME/.gitlab-projects-cache"
  
  if [[ $# -eq 0 ]]; then
    echo "Usage: glprj-sync SEARCH_TERM"
    echo "Example: glprj-sync workers"
    echo "         glprj-sync fl"
    echo ""
    echo "This searches GitLab for projects and adds matches to your cache."
    return 1
  fi
  
  local search_term="$1"
  echo "Searching GitLab for projects matching '$search_term'..."
  
  # Use git ls-remote to search (SSH-based, no token)
  # Try common patterns
  local found=0
  local patterns=(
    "cloudflare/${search_term}"
    "cloudflare/${search_term}/*"
    "cloudflare/*/${search_term}"
  )
  
  for pattern in "${patterns[@]}"; do
    # This is a heuristic - we try to ls-remote and see if it works
    # Not perfect but uses SSH
    echo "Trying pattern: $pattern" >&2
  done
  
  echo ""
  echo "For now, manually browse GitLab and use glprj-add to add projects:"
  echo "  1. Visit: https://gitlab.cfdata.org/cloudflare"
  echo "  2. Search for: $search_term"
  echo "  3. Copy project path (e.g., cloudflare/fl/fl2)"
  echo "  4. Run: glprj-add cloudflare/fl/fl2"
}

# Add a project to cache manually
glprj-add() {
  local cache_file="$HOME/.gitlab-projects-cache"

  if [[ $# -eq 0 ]]; then
    echo "Usage: glprj-add PROJECT_PATH"
    echo "Example: glprj-add cloudflare/fl/fl2"
    return 1
  fi

  local project_path="$1"

  # Verify project exists on GitLab via SSH
  echo "Verifying project exists on GitLab..."
  if git ls-remote "git@gitlab.cfdata.org:${project_path}.git" HEAD &>/dev/null; then
    echo "$project_path" >> "$cache_file"
    sort -u "$cache_file" -o "$cache_file"
    echo "Added $project_path to cache"
  else
    echo "Error: Project $project_path not found on GitLab"
    return 1
  fi
}

# Search GitLab and add projects interactively (requires browsing)
glprj-search() {
  echo "Opening GitLab in browser to search for projects..."
  echo "Copy project paths and use 'glprj-add <path>' to add them"

  # Try to open browser
  if command -v open &>/dev/null; then
    open "https://gitlab.cfdata.org/cloudflare"
  elif command -v xdg-open &>/dev/null; then
    xdg-open "https://gitlab.cfdata.org/cloudflare"
  else
    echo "Visit: https://gitlab.cfdata.org/cloudflare"
  fi
}

# Refresh cache by fetching all projects from GitLab
glprj-refresh() {
  local cache_file="$HOME/.gitlab-projects-cache"
  local api_url="https://gitlab.cfdata.org/api/v4"
  local temp_file=$(mktemp)

  # Check if token is set
  if [[ -z "$GITLAB_TOKEN" ]]; then
    echo "❌ GITLAB_TOKEN not set"
    echo ""
    echo "To fetch all ~9000 projects, you need a GitLab personal access token:"
    echo ""
    echo "Setup (one-time):"
    echo "  1. Visit: https://gitlab.cfdata.org/-/profile/personal_access_tokens"
    echo "  2. Click 'Add new token'"
    echo "  3. Name: 'CLI Access'"
    echo "  4. Scopes: Check 'read_api'"
    echo "  5. Click 'Create personal access token'"
    echo "  6. Copy the token"
    echo ""
    echo "Then add to ~/.zshrc:"
    echo "  export GITLAB_TOKEN='glpat-xxxxxxxxxxxxxxxxxxxx'"
    echo ""
    echo "And reload: source ~/.zshrc"
    echo ""
    echo "After that, run 'glprj-refresh' again."
    return 1
  fi

  echo "Fetching all GitLab projects from API..."
  echo "This will take a few minutes for ~9000 projects..."
  echo ""

  local page=1
  local total_projects=0

  while true; do
    echo -ne "\rFetching page $page... (${total_projects} projects so far)"

    # Fetch page from GitLab API with token
    local response=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
      "${api_url}/projects?per_page=100&page=${page}&simple=true&order_by=id" 2>/dev/null)

    # Check if response is empty
    if [[ -z "$response" ]] || [[ "$response" == "[]" ]]; then
      break
    fi

    # Check for API error
    if echo "$response" | grep -q '"message".*"401'; then
      echo ""
      echo ""
      echo "❌ Invalid token. Please check your GITLAB_TOKEN."
      rm "$temp_file"
      return 1
    fi

    # Extract project paths using Python script
    local extracted=$(echo "$response" | python3 "$HOME/.glprj_extract.py")

    # Check if we got any projects from this page
    if [[ -z "$extracted" ]]; then
      # No projects on this page, we're done
      break
    fi

    # Append to temp file
    echo "$extracted" >> "$temp_file"

    # Update count
    local new_count=$(wc -l < "$temp_file" 2>/dev/null || echo 0)
    total_projects=$new_count

    ((page++))

    # Safety limit
    if [[ $page -gt 100 ]]; then
      echo ""
      echo "Reached page limit (100 pages), stopping."
      break
    fi

    # Small delay to be nice to API
    sleep 0.1
  done

  echo ""
  echo ""

  if [[ $total_projects -eq 0 ]]; then
    echo "❌ No projects fetched."
    rm "$temp_file"
    return 1
  fi

  # Sort and deduplicate
  sort -u "$temp_file" > "$cache_file"
  rm "$temp_file"

  echo "✓ Successfully fetched and cached $total_projects projects"
  echo "  Cache location: $cache_file"
  echo ""
  echo "Run 'glprj' to browse all projects!"
}

# Show current cache
glprj-list() {
  local cache_file="$HOME/.gitlab-projects-cache"

  if [[ ! -f "$cache_file" ]]; then
    echo "No cache file found. Run glprj-init first."
    return 1
  fi

  echo "Cached GitLab projects ($(wc -l < "$cache_file") total):"
  cat "$cache_file"
}

# Edit cache manually
glprj-edit() {
  local cache_file="$HOME/.gitlab-projects-cache"
  ${EDITOR:-vim} "$cache_file"
}
