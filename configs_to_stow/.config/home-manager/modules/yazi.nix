{ pkgs, ... }:

{
  home.packages = with pkgs; [ mdcat ];

  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    plugins = {
      piper = pkgs.yaziPlugins.piper;
    };
    settings = {
      mgr = {
        show_hidden = true;
        sort_dir_first = true;
        ratio = [ 1 2 5 ];
      };
      plugin = {
        prepend_previewers = [
          { name = "*.md"; run = "piper -- mdcat --ansi --local --columns=\"$w\" \"$1\""; }
          { name = "*.markdown"; run = "piper -- mdcat --ansi --local --columns=\"$w\" \"$1\""; }
          { name = "*.mdown"; run = "piper -- mdcat --ansi --local --columns=\"$w\" \"$1\""; }
          { name = "*.mkd"; run = "piper -- mdcat --ansi --local --columns=\"$w\" \"$1\""; }
          { name = "*.mdx"; run = "piper -- mdcat --ansi --local --columns=\"$w\" \"$1\""; }
        ];
      };
    };
  };
}
