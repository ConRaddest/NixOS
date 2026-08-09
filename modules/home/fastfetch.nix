{ ... }:

{
  flake.lib.homeModules.fastfetch =
    { config, pkgs, ... }:

    let
      colors = config.lib.stylix.colors.withHashtag;
    in
    {
      home.packages = [ pkgs.fastfetch ];

      xdg.configFile."fastfetch/logo.txt".text = ''
        ███╗   ██╗ ██████╗ ███████╗
        ████╗  ██║██╔═══██╗██╔════╝
        ██╔██╗ ██║██║   ██║███████╗
        ██║╚██╗██║██║   ██║╚════██║
        ██║ ╚████║╚██████╔╝███████║
        ╚═╝  ╚═══╝ ╚═════╝ ╚══════╝
      '';

      xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
        logo = {
          type = "file";
          source = "~/.config/fastfetch/logo.txt";
          color."1" = colors.base0D;
          padding = {
            top = 0;
            right = 3;
          };
        };
        display = {
          separator = "  ";
          color = {
            keys = colors.base0D;
            title = colors.base0D;
            separator = colors.base0D;
          };
        };
        modules = [
          {
            type = "os";
            key = "system";
          }
          {
            type = "kernel";
            key = "kernel";
          }
          {
            type = "uptime";
            key = "uptime";
          }
          {
            type = "cpu";
            key = "cpu";
          }
          {
            type = "memory";
            key = "memory";
          }
          {
            type = "disk";
            key = "disk";
          }
        ];
      };
    };
}
