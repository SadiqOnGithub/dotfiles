{ config, pkgs, lib, ... }:

{
  home.username = "sadiq";
  home.homeDirectory = "/home/sadiq";
  home.stateVersion = "25.05";

  home.sessionVariables = {
    LC_ALL = "en_US.UTF-8";
  };

  home.packages = with pkgs; [
    eza
    bat
    zoxide
    fzf
    keychain
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
  ];

  programs.home-manager.enable = true;
}
