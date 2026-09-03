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
      PNPM_HOME = "$HOME/.local/share/pnpm";
    };

    # Shell initialization script.
    # Order matters here — plugins must load before compinit, and compinit before p10k.
    initContent = ''
      # Powerlevel10k instant prompt — must stay close to the top of .zshrc so a
      # prompt appears before the rest of this file finishes loading.
      typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
      if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
        source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
      fi

      # -- Shell options --
      setopt histappend          # append to history file instead of overwriting
      setopt sharehistory        # share history across sessions
      setopt histignoreDups      # ignore consecutive duplicate commands
      setopt histignorespace     # don't save commands starting with a space
      setopt incappendhistory    # write to history file immediately
      setopt AUTO_PUSHD          # make cd push to directory stack
      setopt AUTO_CD             # type directory name to cd into it
      setopt CORRECT             # suggest corrections for misspelled commands

      # -- Key bindings --
      bindkey -e                     # use emacs keymap (default, but explicit)
      # Ctrl+Left / Ctrl+Right → jump word (GNOME Terminal sends ^[[1;5C / ^[[1;5D)
      bindkey '^[[1;5C' forward-word
      bindkey '^[[1;5D' backward-word
      # Alt+Left / Alt+Right → jump word (GNOME Terminal sends ^[[1;3C / ^[[1;3D) — parity with bash
      bindkey '^[[1;3C' forward-word
      bindkey '^[[1;3D' backward-word
      # Fallback escape sequences for other terminals / tmux
      bindkey '^[Oc' forward-word
      bindkey '^[Od' backward-word
      bindkey '^[[5C' forward-word
      bindkey '^[[5D' backward-word
      # Extra bash-compatible sequences (\e\e[C / \e\e[D) for bash parity
      bindkey '^[^[[C' forward-word
      bindkey '^[^[[D' backward-word

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
      # Reuse the already-running agent via the keychain env file. Spawning
      # `keychain` on every terminal is ~150ms and prints the banner.
      _kc="$HOME/.keychain/''${HOST}-sh"
      if [[ -z "$SSH_AUTH_SOCK" && -f "$_kc" ]]; then
        source "$_kc"
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

      # -- Shared aliases & functions --
      source "$HOME/.config/shell/aliases.sh"
      source "$HOME/.config/shell/functions.sh"

      # -- Tool initialization --

      # NVM: put the default Node on PATH (~1ms) instead of sourcing nvm.sh (~300ms).
      # `nvm` itself still works; the first call loads nvm.sh.
      if [ -s "$NVM_DIR/nvm.sh" ]; then
        _nvm_default="$(<"$NVM_DIR/alias/default" 2>/dev/null)"
        if [[ -n "$_nvm_default" && -f "$NVM_DIR/alias/$_nvm_default" ]]; then
          _nvm_default="$(<"$NVM_DIR/alias/$_nvm_default")"
        fi
        _nvm_default="''${_nvm_default#v}"
        for _nvm_bin in $NVM_DIR/versions/node/v''${_nvm_default}*/bin(N) $NVM_DIR/versions/node/''${_nvm_default}*/bin(N); do
          path=("$_nvm_bin" $path)
          export NVM_BIN="$_nvm_bin"
          break
        done
        unset _nvm_default _nvm_bin
        nvm() {
          unset -f nvm
          . "$NVM_DIR/nvm.sh"
          [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
          nvm "$@"
        }
      fi

      # Cargo (rust)
      if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
      fi

      # -- Plugin loading (must be before compinit) --

      # kubectl / docker completions: generate once, reuse the cache.
      # Files are sourced after compinit because they call `compdef`.
      _zsh_comp_cache="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh-comps"
      mkdir -p "$_zsh_comp_cache"
      if (( $+commands[kubectl] )); then
        _kubectl_bin="''${commands[kubectl]}"
        if [[ ! -s "$_zsh_comp_cache/kubectl.zsh" || "$_kubectl_bin" -nt "$_zsh_comp_cache/kubectl.zsh" ]]; then
          kubectl completion zsh >| "$_zsh_comp_cache/kubectl.zsh"
        fi
      fi
      if (( $+commands[docker] )); then
        _docker_bin="''${commands[docker]}"
        if [[ ! -s "$_zsh_comp_cache/docker.zsh" || "$_docker_bin" -nt "$_zsh_comp_cache/docker.zsh" ]]; then
          docker completion zsh >| "$_zsh_comp_cache/docker.zsh"
        fi
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
      # Skip the dump-file security rebuild when .zcompdump is less than a day old.
      fpath+=(${pkgs.systemd}/share/zsh/site-functions)
      zstyle ':completion:*' use-cache on
      autoload -Uz compinit
      () {
        setopt local_options extended_glob
        local zcd="''${ZDOTDIR:-$HOME}/.zcompdump"
        if [[ -f "$zcd" && -z $zcd(#qN.mh+24) ]]; then
          compinit -C
        else
          compinit
          [[ -f "$zcd" && -w "$zcd" ]] && zcompile -R "$zcd" &!
        fi
      }

      # -- Additional completions (must be after compinit) --
      [[ -s "$_zsh_comp_cache/kubectl.zsh" ]] && source "$_zsh_comp_cache/kubectl.zsh"
      [[ -s "$_zsh_comp_cache/docker.zsh" ]] && source "$_zsh_comp_cache/docker.zsh"
      unset _kubectl_bin _docker_bin _zsh_comp_cache
      if [ -f "$HOME/.config/kubectl-aliases/.kubectl_aliases" ]; then
        source "$HOME/.config/kubectl-aliases/.kubectl_aliases"
      fi

      # -- Prompt (must be last — p10k overrides completion functions) --
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      if [ -f "$HOME/.p10k.zsh" ]; then
        source "$HOME/.p10k.zsh"
      fi
    '';
  };
}
