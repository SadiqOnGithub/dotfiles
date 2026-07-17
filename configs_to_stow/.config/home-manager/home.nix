{ config, pkgs, ... }:

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

#  programs.git.enable = true;
#  programs.tmux.enable = true;

  programs.home-manager.enable = true;

}
