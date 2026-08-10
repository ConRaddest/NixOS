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
      colors = config.lib.stylix.colors.withHashtag;
      logo = pkgs.runCommand "fastfetch-logo-${hostName}" { nativeBuildInputs = [ pkgs.python3 ]; } ''
        python3 ${self}/scripts/generate-logo.py \
          --seed ${lib.escapeShellArg hostName} \
          --output "$out"
      '';
      dim = colors.base02;
      accent = colors.base0E;
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
            keyColor = dim;
            type = "custom";
            format = "┌──────────────────────Hardware──────────────────────┐";
          }
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
          {
            keyColor = dim;
            type = "custom";
            format = "└────────────────────────────────────────────────────┘";
          }
          "break"
          {
            keyColor = dim;
            type = "custom";
            format = "┌──────────────────────Software──────────────────────┐";
          }
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
          {
            keyColor = dim;
            type = "custom";
            format = "└────────────────────────────────────────────────────┘";
          }
        ];
      };
    };
}
