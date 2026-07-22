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
      eval "$(keychain --eval --agents ssh --inherit any-once ~/.ssh/id_rsa ~/.ssh/github ~/.ssh/ansible)"

      # -- Shared aliases & functions --
      source ~/.config/shell/aliases.sh
      source ~/.config/shell/functions.sh

      # -- Tool initialization --

      # NVM (node version manager)
      [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
      [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

      # Cargo (rust)
      . "$HOME/.cargo/env"

      # -- Plugin loading (must be before compinit) --

      # kubectl completion
      source <(kubectl completion zsh)

      # docker completion
      source <(docker completion zsh)

      # fzf-tab — must load before compinit to hook into the completion system
      source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh

      # zoxide — smarter cd (aliased to z)
      unalias z 2>/dev/null
      eval "$(${pkgs.zoxide}/bin/zoxide init zsh --cmd z)"

      # dircolors — color support for ls, grep, etc.
      if [ -x /usr/bin/dircolors ]; then
        test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
      fi

      # lesspipe — better file previews in less
      [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

      # -- Completions --
      # compinit must run AFTER plugins (fzf-tab, nvm, etc.) and fpath additions.
      fpath+=(${pkgs.systemd}/share/zsh/site-functions)
      zstyle ':completion:*' use-cache on
      compinit

      # -- Additional completions (must be after compinit) --
      source ~/.config/kubectl-aliases/.kubectl_aliases

      # -- Prompt (must be last — p10k overrides completion functions) --
      typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      source ~/.p10k.zsh
    '';
  };
}
