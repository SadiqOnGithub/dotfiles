{ pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    # -- shell options --
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # -- env vars and PATH exports --
    sessionVariables = {
      NVM_DIR = "$HOME/.nvm";
      ANDROID_HOME = "$HOME/Android/Sdk";
      JAVA_HOME = "/usr/lib/jvm/java-17-openjdk-amd64";
      DOCKER_HOST = "unix:///run/user/1000/docker.sock";
      PNPM_HOME = "$HOME/.local/share/pnpm";
    };

    initContent = ''
      # ===========================
      # Shell options
      # ===========================
      setopt histappend
      setopt sharehistory
      setopt histignoreDups
      setopt histignorespace
      setopt incappendhistory
      setopt AUTO_PUSHD
      setopt AUTO_CD
      setopt CORRECT

      # ===========================
      # PATH exports
      # ===========================
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

      # ===========================
      # Source shared aliases & functions
      # ===========================
      source ~/.config/shell/aliases.sh
      source ~/.config/shell/functions.sh

      # ===========================
      # Tool initialization
      # ===========================

      # NVM
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

      # Cargo
      . "$HOME/.cargo/env"

      # kubectl completion
      source <(kubectl completion zsh)

      # docker completion
      source <(docker completion zsh)

      # fzf-tab
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      # zoxide (z function replaces the z alias)
      unalias z 2>/dev/null
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh --cmd z)"

      # dircolors (color support for ls, grep, etc.)
      if [ -x /usr/bin/dircolors ]; then
        test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
      fi

      # lesspipe (better file previews in less)
      [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

      # ===========================
      # Completions
      # ===========================
      fpath+=(${pkgs.systemd}/share/zsh/site-functions)
      zstyle ':completion:*' use-cache on
      compinit
      compdef terraform
      compdef aws

      # ===========================
      # Source kubectl aliases
      # ===========================
      source ~/.config/kubectl-aliases/.kubectl_aliases

      # ===========================
      # Prompt — Powerlevel10k
      # ===========================
      typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      source ~/.p10k.zsh
    '';
  };

}
