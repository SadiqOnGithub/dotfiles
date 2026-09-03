{ ... }:

{
  programs.bash = {
    enable = true;

    shellOptions = [
      "histappend"
      "checkwinsize"
      "globstar"
    ];

    sessionVariables = {
      NVM_DIR = "$HOME/.nvm";
      ANDROID_HOME = "$HOME/Android/Sdk";
      JAVA_HOME = "/usr/lib/jvm/java-17-openjdk-amd64";
      PNPM_HOME = "$HOME/.local/share/pnpm";
    };

    initExtra = ''
      # ===========================
      # Stable SSH agent socket (forwarded keys survive tmux reattach)
      # ===========================
      if [ -n "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$HOME/.ssh/agent.sock" ]; then
        ln -sf "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"
      fi
      if [ -e "$HOME/.ssh/agent.sock" ]; then
        export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
      fi

      # ===========================
      # PATH exports
      # ===========================
      export PATH="$HOME/.nix-profile/bin:$PATH"
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
      # SSH Agent
      # ===========================
      # Reuse the already-running agent; only spawn keychain if it is missing.
      _kc="$HOME/.keychain/$(hostname)-sh"
      if [ -z "$SSH_AUTH_SOCK" ] && [ -f "$_kc" ]; then
        . "$_kc"
      fi
      if ! ssh-add -l >/dev/null 2>&1; then
        ssh_keys=()
        for key in "$HOME/.ssh/id_rsa" "$HOME/.ssh/github" "$HOME/.ssh/ansible"; do
          if [ -f "$key" ]; then
            ssh_keys+=("$key")
          fi
        done
        if [ ''${#ssh_keys[@]} -gt 0 ]; then
          eval "$(keychain --eval --quiet --agents ssh --inherit any-once "''${ssh_keys[@]}")"
        fi
      fi
      unset _kc

      # ===========================
      # Source shared aliases & functions
      # ===========================
      source "$HOME/.config/shell/aliases.sh"
      source "$HOME/.config/shell/functions.sh"

      # ===========================
      # Tool initialization
      # ===========================

      # NVM: put default Node on PATH; load nvm.sh only when `nvm` is called.
      if [ -s "$NVM_DIR/nvm.sh" ]; then
        _nvm_default="$(cat "$NVM_DIR/alias/default" 2>/dev/null)"
        if [ -n "$_nvm_default" ] && [ -f "$NVM_DIR/alias/$_nvm_default" ]; then
          _nvm_default="$(cat "$NVM_DIR/alias/$_nvm_default")"
        fi
        _nvm_default="''${_nvm_default#v}"
        for _nvm_bin in "$NVM_DIR/versions/node/v''${_nvm_default}"*/bin "$NVM_DIR/versions/node/''${_nvm_default}"*/bin; do
          if [ -d "$_nvm_bin" ]; then
            export PATH="$_nvm_bin:$PATH"
            export NVM_BIN="$_nvm_bin"
            break
          fi
        done
        unset _nvm_default _nvm_bin
        nvm() {
          unset -f nvm
          . "$NVM_DIR/nvm.sh"
          [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
          nvm "$@"
        }
      fi

      # Cargo
      if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
      fi

      # kubectl completion
      if command -v kubectl &>/dev/null; then
        source <(kubectl completion bash)
      fi

      # dircolors (color support for ls, grep, etc.)
      if [ -x /usr/bin/dircolors ]; then
        if [ -r "$HOME/.dircolors" ]; then
          eval "$(dircolors -b "$HOME/.dircolors")"
        else
          eval "$(dircolors -b)"
        fi
      fi

      # lesspipe (better file previews in less)
      if [ -x /usr/bin/lesspipe ]; then
        eval "$(SHELL=/bin/sh lesspipe)"
      fi

      # bash-completion
      if ! shopt -oq posix; then
        if [ -f /usr/share/bash-completion/bash_completion ]; then
          . /usr/share/bash-completion/bash_completion
        elif [ -f /etc/bash_completion ]; then
          . /etc/bash_completion
        fi
      fi

      # ===========================
      # Completions
      # ===========================
      complete -C /usr/bin/terraform terraform
      complete -C '/usr/local/bin/aws_completer' aws

      # ===========================
      # Source kubectl aliases
      # ===========================
      if [ -f "$HOME/.config/kubectl-aliases/.kubectl_aliases" ]; then
        source "$HOME/.config/kubectl-aliases/.kubectl_aliases"
      fi

      # ===========================
      # Prompt
      # ===========================

      # Yellow user@host, Cyan folder
      PS1='\[\e[1;33m\]\u@\h \[\e[1;36m\]\W\[\e[0m\] \$ ';
    '';
  };
}
