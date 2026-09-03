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
    "${config.home.homeDirectory}/.local/bin"
  ];

  home.packages = with pkgs; [
    # cli tools
    eza
    bat
    fd
    zoxide
    fzf

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

    # ssh agent manager
    keychain

    # notification utility
    libnotify

    # audio gui
    pavucontrol

    # media player (audio/video playback)
    mpv

    # gtk settings daemon for i3 (applies theme to gtk apps)
    xsettingsd

    # database gui
    dbeaver-bin

    # notes
    obsidian

    # vpn
    tailscale

    # javascript runtime & package manager
    bun

    # power management
    acpi

    # OpenWhispr dependencies (for system-wide pasting)
    xdotool
    wl-clipboard
    wtype
    libsecret
    xdg-utils

    # OpenWhispr - voice dictation (cloud-based, runs via downloaded binary)
    (pkgs.writeShellScriptBin "openwhispr" ''
      cd /home/sadiq/.local/share/openwhispr/OpenWhispr-1.9.2-linux-x64
      exec ./open-whispr "$@"
    '')
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
    ./modules/syncthing.nix
  ];

  programs.home-manager.enable = true;
}
