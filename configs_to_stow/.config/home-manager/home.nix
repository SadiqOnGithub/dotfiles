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
  ];

#  programs.git.enable = true;
#  programs.tmux.enable = true;

  programs.home-manager.enable = true;

}
