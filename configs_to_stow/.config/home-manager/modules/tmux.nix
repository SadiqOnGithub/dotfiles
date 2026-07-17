{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    prefix = "C-Space";
    baseIndex = 1;
    historyLimit = 10000;
    mouse = true;
    keyMode = "vi";
    plugins = with pkgs; [
      tmuxPlugins.resurrect
    ];
    extraConfig = ''
      set -g pane-base-index 1
      set -g renumber-windows on
      set -g set-clipboard on
      set-option -g update-environment "SSH_AUTH_SOCK SSH_CONNECTION SSH_CLIENT SSH_TTY"

      # Shift Alt vim keys to switch windows
      bind -n M-H previous-window
      bind -n M-L next-window

      # Window navigation
      bind -nr C-h select-window -t :-
      bind -nr C-l select-window -t :+

      # Use xsel to copy to the system clipboard
      bind-key -T copy-mode-vi 'y' send-keys -X copy-pipe-and-cancel "xsel -i --clipboard"
      bind-key -T copy-mode-vi 'Enter' send-keys -X copy-pipe-and-cancel "xsel -i --clipboard"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xsel -i --clipboard"

      # Reload config
      bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
    '';
  };
}
