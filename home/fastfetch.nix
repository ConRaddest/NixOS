{ ... }:

{
  flake.lib.homeModules.fastfetch =
    { pkgs, ... }:

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

      xdg.configFile."fastfetch/config.jsonc".text = ''
        {
          "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
          "logo": {
            "type": "file",
            "source": "~/.config/fastfetch/logo.txt",
            "padding": {
              "top": 0,
              "right": 3
            }
          },
          "display": {
            "separator": "  "
          },
          "modules": [
            {
              "type": "os",
              "key": "system"
            },
            {
              "type": "kernel",
              "key": "kernel"
            },
            {
              "type": "uptime",
              "key": "uptime"
            },
            {
              "type": "cpu",
              "key": "cpu"
            },
            {
              "type": "memory",
              "key": "memory"
            },
            {
              "type": "disk",
              "key": "disk"
            }
          ]
        }
      '';
    };
}
