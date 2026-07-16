{ config, pkgs, ... }:

{
  home.username = "sadiq";
  home.homeDirectory = "/home/sadiq";

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    eza
    bat
    i3
#   fd
#   ripgrep
  ];

#  programs.git.enable = true;
#  programs.tmux.enable = true;

  programs.home-manager.enable = true;
}
