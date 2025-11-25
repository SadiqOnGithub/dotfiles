alias bs='source ~/.bash_aliases'
# tools bindings
alias clr='clear'
alias cl='clear'
alias c='code'
# function zc() { zed "$1" && exit; }
alias zc='zed . && exit'
alias z='zed'
alias g='git'
alias gtr='gnome-terminal'
# auto completion for g alias
# complete -o default -F __git_main g
alias k=kubectl
# auto completion for kubectl alias
complete -o default -F __start_kubectl k
alias cc='xclip -selection clipboard'
alias gcn='git log --reverse --format="%H" HEAD..master | head -1 | xargs git checkout'
alias gcp='git checkout HEAD~1'
alias t='tmux'
alias v='NVIM_APPNAME="nvim" nvim'
# alias vn='NVIM_APPNAME="nvim-nornal" nvim'
# alias vl='NVIM_APPNAME="nvim-lazy" nvim'

# system
alias sau='sudo apt update'
alias saug='sudo apt upgrade'
alias asr='apt search'
alias sai='sudo apt install'
alias pag='ps aux | grep'


# ssh bindings
alias s='ssh'
alias srv='ssh srv'
alias sa='eval "$(ssh-agent -s)" && ssh-add'

# cargo bindings
alias cn='cargo new'
alias ca='cargo add'
alias cu='cargo update'
alias cr='cargo run'
alias cb='cargo build'
alias ch='cargo check'
alias ct='cargo test'
alias cdoc='cargo doc --open'
# it tells you non-idiomatic code!
alias cclp='cargo clippy'
alias rust='evcxr'

# npm bindings
alias ni='npm i'
alias nif='npm i --force'
alias nci='npm ci'
alias ncif='npm ci --force'
alias nrd='npm run dev'
alias nrs='npm run start'
alias nrb='npm run build'
alias nrt='npm run test'
alias nrw='npm run web'

# folder bindings
alias sh='cd /home/sadiq/.ssh/'
alias dot='cd /home/sadiq/dotfiles'
alias des='cd /home/sadiq/Desktop'
alias dest='cd /home/sadiq/Desktop/temp'
alias down='cd /home/sadiq/Downloads'
alias docu='cd /home/sadiq/Documents'
alias gls='cd /home/sadiq/Documents/goals'
alias web='cd /home/sadiq/Documents/web'
alias oc='cd /home/sadiq/Documents/web/okhla-consultancy'
alias vs='cd /home/sadiq/Documents/web/okhla-consultancy/vs-ecom'
alias oss='cd /home/sadiq/Documents/web/oss'
alias prac='cd /home/sadiq/Documents/web/prac'
alias rus='cd /home/sadiq/Documents/web/prac/rust'
alias rusp='cd /home/sadiq/Documents/web/prac/rust/rust-prac'
alias 100x='cd /home/sadiq/Documents/web/100x'
alias doc='cd /home/sadiq/Documents/web/docker'
alias k8='cd /home/sadiq/Documents/web/k8'
alias irs='cd /home/sadiq/Documents/web/iris'
alias bali='vi /home/sadiq/.bash_aliases'
alias brc='zed /home/sadiq/.bashrc'

# bt folder bindings
alias bt='cd /home/sadiq/Documents/web/bt'
alias mk='cd /home/sadiq/Documents/web/bt/mk'
alias mki='cd /home/sadiq/Documents/web/bt/mk/mk-infra'
alias ai='cd /home/sadiq/Documents/web/bt/airah'
alias aia='cd /home/sadiq/Documents/web/bt/airah/airah-admin-panel'


# functions
# history grep
function hg() {
  history | grep "$1"
}
# list grep
function lg() {
  ll | grep "$1"
}
# find dir
function fd() {
  find . -type d -name "*$1*"
}
# find file
function ff() {
  find . -type f -name "*$1*"
}

# PORT forwarding of remote servers
function pf() {
  ssh -N -L "$1":localhost:"$1" "$2"
}

# ?
function psf() {
  local remote_host="$1"
  shift

  for local_port in "$@"; do
    ssh -N -L "$local_port":localhost:"$local_port" "$remote_host" &
  done
}

function list_forwarded_ports() {
  lsof -i -n -P | grep 'LISTEN'
}

function stop_pf() {
  local port=$1

  # Check if the port argument is provided
  if [[ -z "$port" ]]; then
    echo "Usage: stop_pf PORT"
    return 1
  fi

  # Find and kill the SSH process forwarding the specified port
  local pid=$(lsof -ti tcp:"$port" -sTCP:LISTEN)

  if [[ -n "$pid" ]]; then
    kill "$pid"
    echo "Port forwarding on port $port stopped."
  else
    echo "No active port forwarding found on port $port."
  fi
}


# Bash themes user@host path

# Yellow user@host, Cyan folder
# PS1='\[\e[1;33m\]\u@\h \[\e[1;36m\]\W\[\e[0m\] \$ '

# Magenta user@host, Green folder
# PS1='\[\e[1;35m\]\u@\h \[\e[1;32m\]\W\[\e[0m\] \$ '

# Blue user@host, Red folder
# PS1='\[\e[1;34m\]\u@\h \[\e[1;31m\]\W\[\e[0m\] \$ '

# Yellow user@host, Cyan folder
PS1='\[\e[1;33m\]\u@\h \[\e[1;36m\]\W\[\e[0m\] \$ '
