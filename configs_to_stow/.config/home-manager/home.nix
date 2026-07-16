{ config, pkgs, ... }:

{
  home.username = "sadiq";
  home.homeDirectory = "/home/sadiq";

  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    eza
    bat
#   i3
#   fd
#   ripgrep


   # statusBar
   # i3status-rust (installed via programs.i3status-rust.enable)

   # screenshot for i3
   flameshot
   #scrot

   


  ];

#  programs.git.enable = true;
#  programs.tmux.enable = true;

  programs.home-manager.enable = true;

  programs.i3status-rust = {
    enable = true;

    bars.default = {
      icons = "awesome6";
      theme = "modern";

      settings = {
        theme.theme = "modern";
        icons.icons = "awesome6";
      };

      blocks = [
        {
          block = "cpu";
          interval = 1;
          format = " CPU $utilization ";
        }

        {
          block = "memory";
          format = " RAM $mem_used.eng(prefix:Gi)/$mem_total.eng(prefix:Gi) ";
        }

        {
          block = "load";
          interval = 1;
          format = " Load $1m ";
        }

        {
          block = "disk_space";
          path = "/";
          format = " SSD $available.eng(prefix:Gi) ";
        }

        {
          block = "net";
          device = "wlp0s20f3";
          interval = 2;
          format = " WiFi $ssid ($signal_strength%) ";
          format_alt = " ↑ $speed_up ↓ $speed_down ";
        }

        {
          block = "battery";
          format = " $percentage ";
        }

        {
          block = "sound";
        }

        {
          block = "time";
          interval = 1;
          format = " $timestamp.datetime(f:'%Y-%m-%d %H:%M:%S') ";
        }
      ];
    };
  };
}
