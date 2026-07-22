{ ... }:

{
  programs.bash = {
    enable = true;

    # -- shell options --
    shellOptions = [
      "histappend"
      "checkwinsize"
      "globstar"
    ];

    # -- env vars and PATH exports --
    sessionVariables = {
      NVM_DIR = "$HOME/.nvm";
      ANDROID_HOME = "$HOME/Android/Sdk";
      JAVA_HOME = "/usr/lib/jvm/java-17-openjdk-amd64";
      DOCKER_HOST = "unix:///run/user/1000/docker.sock";
      PNPM_HOME = "$HOME/.local/share/pnpm";
    };

    initExtra = ''
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
      # SSH Agent
      # ===========================
      eval "$(keychain --eval --agents ssh --inherit any-once ~/.ssh/id_rsa ~/.ssh/github ~/.ssh/ansible)"

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
      source <(kubectl completion bash)

      # dircolors (color support for ls, grep, etc.)
      if [ -x /usr/bin/dircolors ]; then
        test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
      fi

      # lesspipe (better file previews in less)
      [ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

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
      source ~/.config/kubectl-aliases/.kubectl_aliases

      # ===========================
      # Prompt
      # ===========================

      # Yellow user@host, Cyan folder
      PS1='\[\e[1;33m\]\u@\h \[\e[1;36m\]\W\[\e[0m\] \$ ';
    '';
  };
}
