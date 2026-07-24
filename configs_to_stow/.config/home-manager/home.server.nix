{ config, pkgs, lib, ... }:

{
  home.username = "sadiq";
  home.homeDirectory = "/home/sadiq";
  home.stateVersion = "25.05";

  home.sessionVariables = {
    LC_ALL = "en_US.UTF-8";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.nix-profile/bin"
  ];

  home.packages = with pkgs; [
    eza
    bat
    zoxide
    fzf
    keychain

    # vpn
    tailscale

    # power management
    acpi
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
