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

    # screenshot tool for i3
    flameshot
    #scrot

    # notification daemon for i3
    dunst
    libnotify

    # screen lock for i3
    # already installed system-wide as a dependency of i3 (apt)
    # i3lock
  ];

#  programs.git.enable = true;
#  programs.tmux.enable = true;

  programs.home-manager.enable = true;

}
