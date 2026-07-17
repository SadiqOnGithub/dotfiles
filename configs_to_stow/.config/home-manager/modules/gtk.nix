{ pkgs, ... }:

{
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
}
