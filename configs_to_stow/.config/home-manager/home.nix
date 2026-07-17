{ config, pkgs, lib, gitUserName ? "sadiq", ... }:

{
  home.username = "sadiq";
  home.homeDirectory = "/home/sadiq";

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    # cli tools
    eza
    bat
#   fd
#   ripgrep

    # rofi launcher
    rofi

    # clipboard manager for rofi
    haskellPackages.greenclip

    # status bar for i3
    i3blocks

    # brightness control for i3
    brightnessctl

    # screenshot tool for i3
    flameshot
    #scrot

    # notification daemon for i3
    dunst
    libnotify

    # screen lock for i3
    # already installed system-wide as a dependency of i3 (apt)
    # i3lock

    # gtk settings daemon for i3 (applies theme to gtk apps)
    xsettingsd
  ];

  gtk = {
    enable = true;
    theme = {
      name = "Mint-Y-Dark-Aqua";
      package = pkgs.mint-y-icons;
    };
    iconTheme = {
      name = "Mint-Y-Sand";
      package = pkgs.mint-y-icons;
    };
    font = {
      name = "Ubuntu";
      size = 10;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Mint-Y-Dark-Aqua";
      icon-theme = "Mint-Y-Sand";
    };
    "org/gnome/nemo/preferences" = {
      theme-variant = "dark";
    };
  };

  programs.git = {
    enable = true;
    userName = gitUserName;
    userEmail = "sadiqonemail@gmail.com";

    aliases = {
      # -- log --
      ali = "config --get-regexp alias";
      g   = "log --oneline --graph";
      ga  = "log --oneline --graph --all";

      # -- add --
      a  = "add";
      aa = "add .";        # add all
      ap = "add -p";       # add patch

      # -- commit --
      ac   = "commit -am";  # add & commit
      c    = "commit -m";
      cf   = "commit --allow-empty -m";        # fake commit
      cag  = "commit --amend";                 # commit again
      cagf = "commit --amend --allow-empty";   # fake commit again
      cagn = "commit --amend --no-edit";       # commit again no-edit

      # -- switch/checkout --
      sw  = "switch";
      swc = "switch -c";
      ch  = "checkout";

      # -- status --
      s   = "status -s";
      sl  = "status";       # status long
      sv  = "status -v";
      svv = "status -v -v";

      # -- stats --
      st  = "show --stat";
      stc = "show --stat HEAD";  # stat current

      # -- branch --
      b   = "branch";
      ba  = "branch -a";
      br  = "branch -r";
      bF  = "branch -f";
      bm  = "branch --merged";
      bnm = "branch --no-merged";

      # -- remote & sync --
      cl = "clone";
      p  = "push";
      pl = "pull";
      f  = "fetch";
      r  = "remote";
      rv = "remote -v";

      # -- unstage --
      us  = "restore --staged";
      usa = "restore --staged .";  # unstage all

      # -- reset --
      RS = "reset --soft";
      R  = "reset";
      RH = "reset --hard";

      # -- misc --
      rebase-root  = "rebase -i --root";
      delete-alias = "config --global --unset alias.ALI_NAME";
      ce           = "config --global -e";
      dlb          = "!git checkout main && git pull --prune && git branch --merged | grep -v '\\*' | xargs -n 1 git branch -d";
      bclean       = ''!f() { branches=$(git branch --merged ''${1-main} | grep -v " ''${1-main}$"); [ -z "$branches" ] || git branch -d $branches; }; f'';
    };

    extraConfig = {
      safe.directory = "/etc/nginx/sites-available";
      core.editor = "vi";
    };
  };

  programs.tmux = {
    enable = true;
    prefix = "C-Space";
    baseIndex = 1;
    historyLimit = 10000;
    mouse = true;
    keyMode = "vi";
    plugins = with pkgs; [
      tmuxPlugins.resurrect
    ];
    extraConfig = ''
      set -g pane-base-index 1
      set -g renumber-windows on
      set -g set-clipboard on
      set-option -g update-environment "SSH_AUTH_SOCK SSH_CONNECTION SSH_CLIENT SSH_TTY"

      # Shift Alt vim keys to switch windows
      bind -n M-H previous-window
      bind -n M-L next-window

      # Window navigation
      bind -nr C-h select-window -t :-
      bind -nr C-l select-window -t :+

      # Use xsel to copy to the system clipboard
      bind-key -T copy-mode-vi 'y' send-keys -X copy-pipe-and-cancel "xsel -i --clipboard"
      bind-key -T copy-mode-vi 'Enter' send-keys -X copy-pipe-and-cancel "xsel -i --clipboard"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xsel -i --clipboard"

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
    '';
  };

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      mgr = {
        show_hidden = true;
        sort_dir_first = true;
      };
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      # reload
      bs = "source ~/.bashrc";

      # tools
      clr = "clear";
      cl  = "clear";
      c   = "code";
      zc  = "zed . && exit";
      z   = "zed";
      g   = "git";
      gtr = "gnome-terminal";
      cc  = "xclip -selection clipboard";
      gcn = ''git log --reverse --format="%H" HEAD..master | head -1 | xargs git checkout'';
      gcp = "git checkout HEAD~1";
      t   = "tmux";
      v   = "NVIM_APPNAME=\"nvim\" nvim";

      # system
      sau = "sudo apt update";
      saug = "sudo apt upgrade";
      asr = "apt search";
      sai = "sudo apt install";
      pag = "ps aux | grep";

      # ssh
      s   = "ssh";
      srv = "ssh srv";
      sa  = ''eval "$(ssh-agent -s)" && ssh-add'';

      # cargo
      cn   = "cargo new";
      ca   = "cargo add";
      cu   = "cargo update";
      cr   = "cargo run";
      cb   = "cargo build";
      ch   = "cargo check";
      ct   = "cargo test";
      cdoc = "cargo doc --open";
      cclp = "cargo clippy";
      rust = "evcxr";

      # npm/pnpm
      ni   = "pnpm i";
      nif  = "pnpm i --force";
      nci  = "pnpm ci";
      ncif = "pnpm ci --force";
      nrd  = "pnpm run dev";
      nrs  = "pnpm run start";
      nrb  = "pnpm run build";
      nrt  = "pnpm run test";
      nrw  = "pnpm run web";

      # docker
      d   = "docker";
      dp  = "docker ps";
      dpa = "docker ps -a";
      dco = "docker compose up";
      dcd = "docker compose down";

      # kubectl
      kali = "vi ~/.config/kubectl-aliases/.kubectl_aliases";
      kalig = "cat ~/.config/kubectl-aliases/.kubectl_aliases | grep";

      # directories
      brc  = "vi ~/.bashrc";
      bali = "vi ~/.bash_aliases";
      sh   = "cd ~/.ssh/";
      dot  = "cd ~/dotfiles";
      conf = "cd ~/.config";
      home = "cd ~/.config/home-manager";
      vi3  = "cd ~/.config/i3";
      des  = "cd ~/Desktop";
      dest = "cd ~/Desktop/temp";
      down = "cd ~/Downloads";
      docu = "cd ~/Documents";
      gls  = "cd ~/Documents/goals";
      web  = "cd ~/Documents/web";
      oc   = "cd ~/Documents/web/okhla-consultancy";
      vs   = "cd ~/Documents/web/okhla-consultancy/vs-ecom";
      oss  = "cd ~/Documents/web/oss";
      prac = "cd ~/Documents/web/prac";
      rus  = "cd ~/Documents/web/prac/rust";
      rusp = "cd ~/Documents/web/prac/rust/rust-prac";
      "100x" = "cd ~/Documents/web/100x";
      doc  = "cd ~/Documents/web/docker";
      k8   = "cd ~/Documents/web/k8";
      irs  = "cd ~/Documents/web/iris";

      # bt folders
      bt   = "cd ~/Documents/web/bt";
      mk   = "cd ~/Documents/web/bt/mk";
      mki  = "cd ~/Documents/web/bt/mk/mk-infra";
      ai   = "cd ~/Documents/web/bt/airah";
      aia  = "cd ~/Documents/web/bt/airah/airah-admin-panel";
    };

    initExtra = ''
      # source kubectl aliases
      source ~/.config/kubectl-aliases/.kubectl_aliases

      # history grep
      hg() {
        history | grep "$1"
      }
      # list grep
      lg() {
        ll | grep "$1"
      }
      # find dir
      fd() {
        find . -type d -name "*$1*"
      }
      # find file
      ff() {
        find . -type f -name "*$1*"
      }

      # PORT forwarding
      pf() {
        ssh -N -L "$1":localhost:"$1" "$2"
      }

      psf() {
        local remote_host="$1"
        shift
        for local_port in "$@"; do
          ssh -N -L "$local_port":localhost:"$local_port" "$remote_host" &
        done
      }

      list_forwarded_ports() {
        lsof -i -n -P | grep 'LISTEN'
      }

      stop_pf() {
        local port=$1
        if [[ -z "$port" ]]; then
          echo "Usage: stop_pf PORT"
          return 1
        fi
        local pid=$(lsof -ti tcp:"$port" -sTCP:LISTEN)
        if [[ -n "$pid" ]]; then
          kill "$pid"
          echo "Port forwarding on port $port stopped."
        else
          echo "No active port forwarding found on port $port."
        fi
      }

      # Yellow user@host, Cyan folder
      PS1='\[\e[1;33m\]\u@\h \[\e[1;36m\]\W\[\e[0m\] \$ '
    '';
  };

  programs.home-manager.enable = true;

}
