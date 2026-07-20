{ config, pkgs, lib, ... }:

{
  home.username = "sadiq";
  home.homeDirectory = "/home/sadiq";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    # cli tools
    eza
    bat

    # rofi launcher
    rofi

    # clipboard manager for rofi
    haskellPackages.greenclip
    xclip

    # status bar for i3
    i3blocks

    # brightness control for i3
    brightnessctl

    # screenshot tool for i3
    flameshot

    # notification utility
    libnotify

    # gtk settings daemon for i3 (applies theme to gtk apps)
    xsettingsd
  ];

  imports = [
    ./modules/git.nix
    ./modules/tmux.nix
    ./modules/aliases.nix
    ./modules/functions.nix
    ./modules/bash.nix
    ./modules/zsh.nix
    ./modules/yazi.nix
    ./modules/vim.nix
    ./modules/gtk.nix
    ./modules/dunst.nix
    ./modules/i3.nix
  ];

  programs.home-manager.enable = true;
}
