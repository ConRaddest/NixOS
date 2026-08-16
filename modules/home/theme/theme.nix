{ inputs, ... }:

{
  flake.lib.homeModules.theme =
    {
      config,
      font,
      lib,
      pkgs,
      self,
      ...
    }:

    let
      cfg = config.nos.theme;
      flakeDirectory = config.nos.flakeDirectory;
      shellDirectory =
        if flakeDirectory == null then
          "${config.home.homeDirectory}/NixOS/shell"
        else
          "${flakeDirectory}/shell";
      themeDirectory = "${self}/themes/${cfg.name}";
      colorsFile = "${themeDirectory}/colors.toml";
      backgroundsDirectory = "${themeDirectory}/backgrounds";
      selectedWallpaper = "${themeDirectory}/${cfg.wallpaper}";

      theme = if builtins.pathExists colorsFile then fromTOML (builtins.readFile colorsFile) else { };
      mode =
        theme.mode or (if builtins.pathExists "${themeDirectory}/light.mode" then "light" else "dark");
      colors = theme // {
        inherit mode;
        orange = theme.orange or theme.yellow;
        brown = theme.brown or (theme.orange or theme.yellow);
        selection_background = theme.selection_background or theme.selection;
        selection_foreground = theme.selection_foreground or theme.bright_foreground;
      };

      canonicalColorNames = [
        "accent"
        "selection"
        "muted"
        "background"
        "dark_background"
        "darker_background"
        "lighter_background"
        "foreground"
        "dark_foreground"
        "light_foreground"
        "bright_foreground"
        "red"
        "yellow"
        "orange"
        "green"
        "cyan"
        "blue"
        "magenta"
        "brown"
        "bright_red"
        "bright_yellow"
        "bright_green"
        "bright_cyan"
        "bright_blue"
        "bright_magenta"
        "selection_background"
        "selection_foreground"
      ];
      canonicalColors = map (name: colors.${name} or null) canonicalColorNames;
      quickshellColors = removeAttrs colors [ "mode" ];
      quickshellColorsQml = lib.concatStringsSep "\n" (
        [
          "pragma Singleton"
          ""
          "import QtQuick"
          ""
          "QtObject {"
          "  readonly property string mode: ${builtins.toJSON mode}"
        ]
        ++ lib.mapAttrsToList (
          name: value: "  readonly property color ${name}: ${builtins.toJSON value}"
        ) quickshellColors
        ++ [
          "}"
          ""
        ]
      );

      palette = {
        base00 = colors.background;
        base01 = colors.dark_background;
        base02 = colors.selection;
        base03 = colors.muted;
        base04 = colors.dark_foreground;
        base05 = colors.foreground;
        base06 = colors.light_foreground;
        base07 = colors.bright_foreground;
        base08 = colors.red;
        base09 = colors.orange;
        base0A = colors.yellow;
        base0B = colors.green;
        base0C = colors.cyan;
        base0D = colors.blue;
        base0E = colors.magenta;
        base0F = colors.brown;
      };

      backgroundFiles =
        if builtins.pathExists backgroundsDirectory then
          builtins.attrNames (
            lib.filterAttrs (
              _: type:
              builtins.elem type [
                "regular"
                "symlink"
              ]
            ) (builtins.readDir backgroundsDirectory)
          )
        else
          [ ];
    in
    {
      imports = [ inputs.stylix.homeModules.stylix ];

      options.nos.theme = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Theme directory name under themes/.";
        };

        wallpaper = lib.mkOption {
          type = lib.types.str;
          description = "Wallpaper path relative to selected theme directory.";
        };

        directory = lib.mkOption {
          type = lib.types.str;
          readOnly = true;
          internal = true;
        };

        mode = lib.mkOption {
          type = lib.types.enum [
            "dark"
            "light"
          ];
          readOnly = true;
          internal = true;
        };

        backgrounds = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          readOnly = true;
          internal = true;
        };

        colors = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          readOnly = true;
          internal = true;
          description = "Canonical theme colors with standard selection fallbacks.";
        };
      };

      config = {
        assertions = [
          {
            assertion = flakeDirectory != null;
            message = "nos.flakeDirectory must be set for Quickshell development.";
          }
          {
            assertion = builtins.pathExists colorsFile;
            message = "Theme ${cfg.name} must provide themes/${cfg.name}/colors.toml.";
          }
          {
            assertion = builtins.pathExists selectedWallpaper;
            message = "Theme ${cfg.name} wallpaper ${cfg.wallpaper} does not exist.";
          }
          {
            assertion = builtins.elem mode [
              "dark"
              "light"
            ];
            message = "Theme ${cfg.name} mode must be dark or light.";
          }
          {
            assertion = lib.all (color: color != null) canonicalColors;
            message = "Theme ${cfg.name} is missing one or more canonical colors.";
          }
          {
            assertion = lib.all (
              color: color == null || builtins.match "#[0-9a-fA-F]{6}" color != null
            ) canonicalColors;
            message = "Theme ${cfg.name} canonical colors must use #RRGGBB notation.";
          }
        ];

        nos.theme = {
          inherit colors mode;
          backgrounds = map (name: "${backgroundsDirectory}/${name}") backgroundFiles;
          directory = themeDirectory;
        };

        stylix = {
          enable = true;
          autoEnable = true;
          polarity = mode;
          image = selectedWallpaper;
          imageScalingMode = "fill";
          base16Scheme = palette // {
            scheme = cfg.name;
            author = "NixOS Stylix theme engine";
            variant = mode;
          };

          fonts = {
            sansSerif = {
              package = pkgs.adwaita-fonts;
              name = font.system;
            };
            serif = {
              package = pkgs.noto-fonts;
              name = "Noto Serif";
            };
            monospace = {
              package = pkgs.nerd-fonts.jetbrains-mono;
              name = font.mono;
            };
            emoji = {
              package = pkgs.noto-fonts-color-emoji;
              name = "Noto Color Emoji";
            };
            sizes = {
              applications = font.size;
              desktop = font.size;
              popups = font.size;
              terminal = 12;
            };
          };

          cursor = {
            package = pkgs.adwaita-icon-theme;
            name = "Adwaita";
            size = 22;
          };
        };

        home.packages = [
          (pkgs.writeShellScriptBin "nos-shell" ''
            set -euo pipefail
            shell_directory=${lib.escapeShellArg shellDirectory}

            if [[ ! -f "$shell_directory/shell.qml" ]]; then
              printf 'Quickshell config not found: %s\n' "$shell_directory" >&2
              exit 1
            fi

            exec ${pkgs.quickshell}/bin/qs -p "$shell_directory" "$@"
          '')
        ];

        # Make generated singleton visible in mutable source tree. Quickshell can
        # hot reload source files, while qmlls gets active theme color metadata.
        home.activation.linkQuickshellColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          shell_directory=${lib.escapeShellArg shellDirectory}
          if [[ -d "$shell_directory" ]]; then
            run ln -sfn \
              "$HOME/.local/share/nixos-shell/Colors.qml" \
              "$shell_directory/Colors.qml"
          fi
        '';

        home.file = {
          ".local/share/nixos-shell/Colors.qml".text = quickshellColorsQml;
        }
        // builtins.listToAttrs (
          map (name: {
            name = "Pictures/Wallpapers/${cfg.name}/${name}";
            value = {
              source = "${backgroundsDirectory}/${name}";
              force = true;
            };
          }) backgroundFiles
        );

      };
    };
}
