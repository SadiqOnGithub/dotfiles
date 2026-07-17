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

  programs.home-manager.enable = true;

}
