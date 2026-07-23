{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    # Home-manager built-in modules.
    # NOTE: enableCompletion is disabled because we call compinit manually in initContent.
    # This is required so that compinit runs AFTER all plugins and fpath additions.
    enableCompletion = false;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # Environment variables available to all zsh sessions.
    sessionVariables = {
      NVM_DIR = "$HOME/.nvm";
      ANDROID_HOME = "$HOME/Android/Sdk";
      JAVA_HOME = "/usr/lib/jvm/java-17-openjdk-amd64";
      DOCKER_HOST = "unix:///run/user/1000/docker.sock";
      PNPM_HOME = "$HOME/.local/share/pnpm";
    };

    # Shell initialization script.
    # Order matters here — plugins must load before compinit, and compinit before p10k.
    initContent = ''
      # -- Shell options --
      setopt histappend          # append to history file instead of overwriting
      setopt sharehistory        # share history across sessions
      setopt histignoreDups      # ignore consecutive duplicate commands
      setopt histignorespace     # don't save commands starting with a space
      setopt incappendhistory    # write to history file immediately
      setopt AUTO_PUSHD          # make cd push to directory stack
      setopt AUTO_CD             # type directory name to cd into it
      setopt CORRECT             # suggest corrections for misspelled commands

      # -- PATH exports --
      export PATH="$HOME/.local/bin:$PATH"
      export PATH="$PATH:$ANDROID_HOME/emulator"
      export PATH="$PATH:$ANDROID_HOME/platform-tools"
      export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin"
      export PATH="$PATH:$JAVA_HOME/bin"
      export PATH="$PATH:$HOME/.pulumi/bin"
      export PATH="$PATH:$HOME/.linkerd2/bin"
      export PATH="$PATH:$HOME/.opencode/bin"
      case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
      esac

      # -- SSH Agent --
      ssh_keys=()
      for key in "$HOME/.ssh/id_rsa" "$HOME/.ssh/github" "$HOME/.ssh/ansible"; do
        if [ -f "$key" ]; then
          ssh_keys+=("$key")
        fi
      done
      if [ ''${#ssh_keys[@]} -gt 0 ]; then
        eval "$(keychain --eval --agents ssh --inherit any-once "''${ssh_keys[@]}")"
      fi

      # -- Shared aliases & functions --
      source "$HOME/.config/shell/aliases.sh"
      source "$HOME/.config/shell/functions.sh"

      # -- Tool initialization --

      # NVM (node version manager)
      if [ -s "$NVM_DIR/nvm.sh" ]; then
        \. "$NVM_DIR/nvm.sh"
      fi
      if [ -s "$NVM_DIR/bash_completion" ]; then
        \. "$NVM_DIR/bash_completion"
      fi

      # Cargo (rust)
      if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
      fi

      # -- Plugin loading (must be before compinit) --

      # kubectl completion
      if command -v kubectl &>/dev/null; then
        source <(kubectl completion zsh)
      fi

      # docker completion
      if command -v docker &>/dev/null; then
        source <(docker completion zsh)
      fi

      # fzf-tab — must load before compinit to hook into the completion system
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      # zoxide — smarter cd (aliased to z)
      unalias z 2>/dev/null
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh --cmd z)"

      # dircolors — color support for ls, grep, etc.
      if [ -x /usr/bin/dircolors ]; then
        if [ -r "$HOME/.dircolors" ]; then
          eval "$(dircolors -b "$HOME/.dircolors")"
        else
          eval "$(dircolors -b)"
        fi
      fi

      # lesspipe — better file previews in less
      if [ -x /usr/bin/lesspipe ]; then
        eval "$(SHELL=/bin/sh lesspipe)"
      fi

      # -- Completions --
      # compinit must run AFTER plugins (fzf-tab, nvm, etc.) and fpath additions.
      fpath+=(${pkgs.systemd}/share/zsh/site-functions)
      zstyle ':completion:*' use-cache on
      autoload -Uz compinit
      compinit

      # -- Additional completions (must be after compinit) --
      if [ -f "$HOME/.config/kubectl-aliases/.kubectl_aliases" ]; then
        source "$HOME/.config/kubectl-aliases/.kubectl_aliases"
      fi

      # -- Prompt (must be last — p10k overrides completion functions) --
      typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      if [ -f "$HOME/.p10k.zsh" ]; then
        source "$HOME/.p10k.zsh"
      fi
    '';
  };
}
