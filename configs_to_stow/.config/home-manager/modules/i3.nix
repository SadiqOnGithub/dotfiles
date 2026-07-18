{ pkgs, ... }:

{
  xdg.dataFile."xsessions/i3.desktop".text = ''
    [Desktop Entry]
    Name=i3
    Comment=improved dynamic tiling window manager
    Exec=i3
    TryExec=i3
    Type=Application
    X-LightDM-DesktopName=i3
    DesktopNames=i3
    Keywords=tiling;wm;windowmanager;window;manager;
  '';

  xsession.windowManager.i3 = {
    enable = true;

    config = {
      modifier = "Mod4";

      fonts = {
        names = [ "monospace" ];
        size = 10.0;
      };

      startup = [
        {
          command = "dex --autostart --environment i3";
          always = false;
          notification = false;
        }
        {
          command = "xss-lock --transfer-sleep-lock -- i3lock --nofork";
          always = false;
          notification = false;
        }
        {
          command = "nm-applet";
          always = false;
          notification = false;
        }
        {
          command = "flameshot";
          always = false;
          notification = false;
        }
        {
          command = "${pkgs.haskellPackages.greenclip}/bin/greenclip daemon";
          always = true;
          notification = false;
        }
        {
          command = "xsettingsd";
          always = false;
          notification = false;
        }
        {
          command = "sh -c 'sleep 2 && xinput set-prop \"ETPS/2 Elantech Touchpad\" \"libinput Natural Scrolling Enabled\" 1'";
          always = true;
          notification = false;
        }
      ];

      keybindings = let
        m = "Mod4";
      in {
        # applications
        "${m}+Return" = "exec i3-sensible-terminal";
        "${m}+Shift+q" = "kill";
        "Mod1+F4" = "kill";

        # rofi
        "${m}+d" = "exec --no-startup-id rofi -show drun";
        "${m}+Shift+d" = "exec --no-startup-id rofi -show run";
        "${m}+Shift+w" = "exec --no-startup-id rofi -show window";
        "${m}+Shift+s" = "exec --no-startup-id rofi -show ssh";
        "${m}+c" = "exec --no-startup-id greenclip print | rofi -dmenu -p \"Clipboard\"";
        "Mod1+F2" = "exec --no-startup-id rofi -show run";

        # focus
        "${m}+j" = "focus left";
        "${m}+k" = "focus down";
        "${m}+l" = "focus up";
        "${m}+semicolon" = "focus right";
        "${m}+Left" = "focus left";
        "${m}+Down" = "focus down";
        "${m}+Up" = "focus up";
        "${m}+Right" = "focus right";

        # move
        "${m}+Shift+j" = "move left";
        "${m}+Shift+k" = "move down";
        "${m}+Shift+l" = "move up";
        "${m}+Shift+semicolon" = "move right";
        "${m}+Shift+Left" = "move left";
        "${m}+Shift+Down" = "move down";
        "${m}+Shift+Up" = "move up";
        "${m}+Shift+Right" = "move right";

        # split
        "${m}+h" = "split h";
        "${m}+v" = "split v";

        # fullscreen
        "${m}+f" = "fullscreen toggle";

        # layout
        "${m}+s" = "layout stacking";
        "${m}+w" = "layout tabbed";
        "${m}+e" = "layout toggle split";

        # floating
        "${m}+Shift+space" = "floating toggle";
        "${m}+space" = "focus mode_toggle";

        # focus parent
        "${m}+a" = "focus parent";

        # workspaces
        "${m}+1" = "workspace number 1";
        "${m}+2" = "workspace number 2";
        "${m}+3" = "workspace number 3";
        "${m}+4" = "workspace number 4";
        "${m}+5" = "workspace number 5";
        "${m}+6" = "workspace number 6";
        "${m}+7" = "workspace number 7";
        "${m}+8" = "workspace number 8";
        "${m}+9" = "workspace number 9";
        "${m}+0" = "workspace number 10";

        # move to workspace
        "${m}+Shift+1" = "move container to workspace number 1";
        "${m}+Shift+2" = "move container to workspace number 2";
        "${m}+Shift+3" = "move container to workspace number 3";
        "${m}+Shift+4" = "move container to workspace number 4";
        "${m}+Shift+5" = "move container to workspace number 5";
        "${m}+Shift+6" = "move container to workspace number 6";
        "${m}+Shift+7" = "move container to workspace number 7";
        "${m}+Shift+8" = "move container to workspace number 8";
        "${m}+Shift+9" = "move container to workspace number 9";
        "${m}+Shift+0" = "move container to workspace number 10";

        # reload / restart / exit
        "${m}+Shift+c" = "reload";
        "${m}+Shift+r" = "restart";
        "${m}+Shift+e" = "exit";

        # resize mode
        "${m}+r" = "mode resize";

        # bar
        "${m}+b" = "bar mode toggle";

        # dunst
        "${m}+grave" = "exec dunstctl close";
        "${m}+shift+grave" = "exec dunstctl history-pop";
        "${m}+ctrl+grave" = "exec dunstctl close-all";
        "${m}+m" = "exec dunstctl set-paused toggle";

        # screen lock
        "${m}+ctrl+l" = "exec LC_ALL=en_US.UTF-8 i3lock -c 1a1b26";

        # screenshot
        "Print" = "exec --no-startup-id flameshot gui";

        # volume
        "XF86AudioRaiseVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5% && dunstify -h int:value:\"$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+%' | head -1 | tr -d '%')\" -h string:x-dunst-stack-tag:volumenotif \"Volume\"";
        "XF86AudioLowerVolume" = "exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5% && dunstify -h int:value:\"$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\\d+%' | head -1 | tr -d '%')\" -h string:x-dunst-stack-tag:volumenotif \"Volume\"";
        "XF86AudioMute" = "exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && dunstify -h string:x-dunst-stack-tag:volumenotif \"$(pactl get-sink-mute @DEFAULT_SINK@)\"";
        "XF86AudioMicMute" = "exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && killall -SIGUSR1 i3status-rs";

        # brightness
        "XF86MonBrightnessUp" = "exec --no-startup-id brightnessctl set +5%";
        "XF86MonBrightnessDown" = "exec --no-startup-id brightnessctl set 5%-";
      };

      floating.criteria = [ ];

      bars = [
        {
          statusCommand = "i3blocks";
          position = "bottom";
        }
      ];

      modes = {
        resize = {
          "j" = "resize shrink width 10 px or 10 ppt";
          "k" = "resize grow height 10 px or 10 ppt";
          "l" = "resize shrink height 10 px or 10 ppt";
          "semicolon" = "resize grow width 10 px or 10 ppt";
          "Left" = "resize shrink width 10 px or 10 ppt";
          "Down" = "resize grow height 10 px or 10 ppt";
          "Up" = "resize shrink height 10 px or 10 ppt";
          "Right" = "resize grow width 10 px or 10 ppt";
          "Return" = "mode default";
          "Escape" = "mode default";
          "Mod4+r" = "mode default";
        };
      };
    };
  };
}
