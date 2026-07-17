{ pkgs, gitUserName ? "sadiq", ... }:

{
  programs.git = {
    enable = true;
    userName = gitUserName;
    userEmail = "sadiqonemail@gmail.com";

    aliases = {
      # -- log --
      ali = "config --get-regexp alias";
      g   = "log --oneline --graph";
      ga  = "log --oneline --graph --all";

      # -- add --
      a  = "add";
      aa = "add .";        # add all
      ap = "add -p";       # add patch

      # -- commit --
      ac   = "commit -am";  # add & commit
      c    = "commit -m";
      cf   = "commit --allow-empty -m";        # fake commit
      cag  = "commit --amend";                 # commit again
      cagf = "commit --amend --allow-empty";   # fake commit again
      cagn = "commit --amend --no-edit";       # commit again no-edit

      # -- switch/checkout --
      sw  = "switch";
      swc = "switch -c";
      ch  = "checkout";

      # -- status --
      s   = "status -s";
      sl  = "status";       # status long
      sv  = "status -v";
      svv = "status -v -v";

      # -- stats --
      st  = "show --stat";
      stc = "show --stat HEAD";  # stat current

      # -- branch --
      b   = "branch";
      ba  = "branch -a";
      br  = "branch -r";
      bF  = "branch -f";
      bm  = "branch --merged";
      bnm = "branch --no-merged";

      # -- remote & sync --
      cl = "clone";
      p  = "push";
      pl = "pull";
      f  = "fetch";
      r  = "remote";
      rv = "remote -v";

      # -- unstage --
      us  = "restore --staged";
      usa = "restore --staged .";  # unstage all

      # -- reset --
      RS = "reset --soft";
      R  = "reset";
      RH = "reset --hard";

      # -- misc --
      rebase-root  = "rebase -i --root";
      delete-alias = "config --global --unset alias.ALI_NAME";
      ce           = "config --global -e";
      dlb          = "!git checkout main && git pull --prune && git branch --merged | grep -v '\\*' | xargs -n 1 git branch -d";
      bclean       = ''!f() { branches=$(git branch --merged ''${1-main} | grep -v " ''${1-main}$"); [ -z "$branches" ] || git branch -d $branches; }; f'';
    };

    extraConfig = {
      safe.directory = "/etc/nginx/sites-available";
      core.editor = "vi";
    };
  };
}
