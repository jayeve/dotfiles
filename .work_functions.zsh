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
eval "$(temporal completion zsh)"
