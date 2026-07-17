{ ... }:

{
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      mgr = {
        show_hidden = true;
        sort_dir_first = true;
      };
    };
  };
}
