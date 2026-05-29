{ ... }:

{
  programs.yazi = {
    enable = true;
    settings = {
      manager = {
        show_hidden = false;
        show_symlink = true;
        sort_by = "natural";
        sort_dir_first = true;
      };
    };
  };
}
