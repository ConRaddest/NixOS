{ ... }:

{
  flake.lib.homeModules.fastfetch =
    {
      config,
      hostName,
      lib,
      pkgs,
      self,
      ...
    }:

    let
      colors = config.nos.theme.colors;
      logo = pkgs.runCommand "fastfetch-logo-${hostName}" { nativeBuildInputs = [ pkgs.python3 ]; } ''
        python3 ${self}/scripts/generate-logo.py \
          --seed ${lib.escapeShellArg hostName} \
          --output "$out"
      '';
      dim = colors.selection;
      accent = colors.secondary;
    in
    {
      home.packages = [ pkgs.fastfetch ];

      xdg.configFile."fastfetch/logo.txt".source = logo;

      xdg.configFile."fastfetch/config.jsonc".text = builtins.toJSON {
        "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";
        logo = {
          type = "file";
          source = "~/.config/fastfetch/logo.txt";
          color."1" = accent;
          padding = {
            top = 0;
            right = 3;
          };
        };
        display = {
          disableLinewrap = true;
          separator = "  ";
        };
        modules = [
          {
            type = "host";
            key = " PC";
            keyColor = accent;
          }
          {
            type = "cpu";
            key = "│ ├";
            showPeCoreCount = true;
            keyColor = accent;
          }
          {
            type = "gpu";
            key = "│ ├";
            detectionMethod = "pci";
            format = "{name}";
            keyColor = accent;
          }
          {
            type = "display";
            key = "│ ├󱄄";
            keyColor = accent;
          }
          {
            type = "memory";
            key = "│ ├";
            keyColor = accent;
          }
          {
            type = "battery";
            key = "└ └󰁹";
            keyColor = accent;
          }
          "break"
          {
            type = "os";
            key = " OS";
            keyColor = accent;
          }
          {
            type = "kernel";
            key = "│ ├";
            keyColor = accent;
          }
          {
            type = "uptime";
            key = "│ ├󱫐";
            keyColor = accent;
          }
          {
            type = "packages";
            key = "│ ├󰏖";
            keyColor = accent;
          }
          {
            type = "shell";
            key = "│ ├";
            keyColor = accent;
          }
          {
            type = "wm";
            key = "│ ├";
            keyColor = accent;
          }
          {
            type = "theme";
            key = "│ ├󰉼";
            keyColor = accent;
          }
          {
            type = "terminal";
            key = "│ ├";
            keyColor = accent;
          }
          {
            type = "terminalfont";
            key = "└ └";
            keyColor = accent;
          }
          "break"
          {
            type = "colors";
          }
        ];
      };
    };
}
