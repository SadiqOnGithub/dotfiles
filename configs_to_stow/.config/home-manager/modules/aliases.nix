{ ... }:

{
  home.file.".config/shell/aliases.sh".text = ''
    # ===========================
    # Reload
    # ===========================
    alias bs="source ~/.bashrc"
    alias zs="source ~/.zshrc"
    alias hms="home-manager switch"

    # ===========================
    # Tools
    # ===========================
    alias clr="clear"
    alias cl="clear"
    alias c="code"
    alias zc="zed . && exit"
    alias z="zed"
    alias g="git"
    alias gtr="gnome-terminal"
    alias cc="xclip -selection clipboard"
    alias gcn='git log --reverse --format="%H" HEAD..master | head -1 | xargs git checkout'
    alias gcp="git checkout HEAD~1"
    alias t="tmux"
    alias v='NVIM_APPNAME="nvim" nvim'

    # ===========================
    # System
    # ===========================
    alias sau="sudo apt update"
    alias saug="sudo apt upgrade"
    alias asr="apt search"
    alias sai="sudo apt install"
    alias pag="ps aux | grep"

    # ===========================
    # SSH
    # ===========================
    alias s="ssh"
    alias srv="ssh srv"
    alias sa='eval "$(ssh-agent -s)" && ssh-add'

    # ===========================
    # Cargo
    # ===========================
    alias cn="cargo new"
    alias ca="cargo add"
    alias cu="cargo update"
    alias cr="cargo run"
    alias cb="cargo build"
    alias ch="cargo check"
    alias ct="cargo test"
    alias cdoc="cargo doc --open"
    alias cclp="cargo clippy"
    alias rust="evcxr"

    # ===========================
    # npm/pnpm
    # ===========================
    alias ni="pnpm i"
    alias nif="pnpm i --force"
    alias nci="pnpm ci"
    alias ncif="pnpm ci --force"
    alias nrd="pnpm run dev"
    alias nrs="pnpm run start"
    alias nrb="pnpm run build"
    alias nrt="pnpm run test"
    alias nrw="pnpm run web"

    # ===========================
    # Docker
    # ===========================
    alias d="docker"
    alias dp="docker ps"
    alias dpa="docker ps -a"
    alias dco="docker compose up"
    alias dcd="docker compose down"

    # ===========================
    # kubectl
    # ===========================
    alias kali="vi ~/.config/kubectl-aliases/.kubectl_aliases"
    alias kalig="cat ~/.config/kubectl-aliases/.kubectl_aliases | grep"

    # ===========================
    # ls (from ubuntu .bashrc)
    # ===========================
    alias ll="ls -alF"
    alias la="ls -A"
    alias l="ls -CF"

    # ===========================
    # alert (from ubuntu .bashrc)
    # ===========================
    alias alert="notify-send --urgency=low -i \"\$([ \$? = 0 ] && echo terminal || echo error)\" \"\$(history|tail -n1|sed -e 's/^\\s*[0-9]\\+\\s*//;s/[;&|]\\s*alert\$//')\""

    # ===========================
    # Directories
    # ===========================
    alias brc="vi ~/.bashrc"
    alias mbrc="vi ~/.config/home-manager/modules/bash.nix"
    alias bali="vi ~/.bash_aliases"
    alias sh="cd ~/.ssh/"
    alias dot="cd ~/dotfiles"
    alias conf="cd ~/.config"
    alias home="cd ~/.config/home-manager"
    alias vi3="cd ~/.config/i3"
    alias des="cd ~/Desktop"
    alias dest="cd ~/Desktop/temp"
    alias down="cd ~/Downloads"
    alias docu="cd ~/Documents"
    alias gls="cd ~/Documents/goals"
    alias web="cd ~/Documents/web"
    alias oc="cd ~/Documents/web/okhla-consultancy"
    alias vs="cd ~/Documents/web/okhla-consultancy/vs-ecom"
    alias oss="cd ~/Documents/web/oss"
    alias prac="cd ~/Documents/web/prac"
    alias rus="cd ~/Documents/web/prac/rust"
    alias rusp="cd ~/Documents/web/prac/rust/rust-prac"
    alias 100x="cd ~/Documents/web/100x"
    alias doc="cd ~/Documents/web/docker"
    alias k8="cd ~/Documents/web/k8"
    alias irs="cd ~/Documents/web/iris"

    # ===========================
    # bt folders
    # ===========================
    alias bt="cd ~/Documents/web/bt"
    alias mk="cd ~/Documents/web/bt/mk"
    alias mki="cd ~/Documents/web/bt/mk/mk-infra"
    alias ai="cd ~/Documents/web/bt/airah"
    alias aia="cd ~/Documents/web/bt/airah/airah-admin-panel"
  '';
}
