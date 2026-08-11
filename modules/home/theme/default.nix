{ inputs, ... }:

{
  flake.lib.homeModules.theme =
    {
      config,
      font,
      lib,
      pkgs,
      ...
    }:

    let
      cfg = config.nos.theme;
      base16Names = [
        "base00"
        "base01"
        "base02"
        "base03"
        "base04"
        "base05"
        "base06"
        "base07"
        "base08"
        "base09"
        "base0A"
        "base0B"
        "base0C"
        "base0D"
        "base0E"
        "base0F"
      ];
      colors = config.lib.stylix.colors.withHashtag;
      roleColors = colors // cfg.extraColors;
    in
    {
      imports = [ inputs.stylix.homeModules.stylix ];

      options.nos.theme = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Human-readable name of selected theme.";
        };

        polarity = lib.mkOption {
          type = lib.types.enum [
            "dark"
            "light"
          ];
          description = "Selected theme polarity.";
        };

        wallpaper = lib.mkOption {
          type = lib.types.path;
          description = "Wallpaper bundled with selected theme.";
        };

        palette = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          description = "Hashtagged Base16 palette for selected theme.";
        };

        extraColors = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
          description = "Named non-Base16 colors available to semantic roles.";
        };

        roles = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          description = "Semantic color roles mapped to Base16 palette entries or named extra colors.";
        };

        colors = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          readOnly = true;
          internal = true;
          description = "Resolved semantic colors in #RRGGBB form.";
        };
      };

      config = {
        assertions = [
          {
            assertion = lib.all (name: builtins.hasAttr name cfg.palette) base16Names;
            message = "Theme ${cfg.name} must define every Base16 color from base00 through base0F.";
          }
          {
            assertion = lib.all (color: builtins.match "#[0-9a-fA-F]{6}" color != null) (
              builtins.attrValues (cfg.palette // cfg.extraColors)
            );
            message = "Theme ${cfg.name} palette and extra colors must use #RRGGBB notation.";
          }
          {
            assertion = lib.all (colorName: builtins.hasAttr colorName roleColors) (
              builtins.attrValues cfg.roles
            );
            message = "Theme ${cfg.name} roles must reference a Base16 palette entry or named extra color.";
          }
        ];

        nos.theme.colors = lib.mapAttrs (_: colorName: roleColors.${colorName}) cfg.roles;

        stylix = {
          enable = true;
          autoEnable = true;
          polarity = cfg.polarity;
          image = cfg.wallpaper;
          imageScalingMode = "fill";
          base16Scheme = cfg.palette // {
            scheme = cfg.name;
            author = "NixOS configuration";
            variant = cfg.polarity;
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

        home.file."Pictures/Wallpapers/${builtins.baseNameOf cfg.wallpaper}" = {
          source = cfg.wallpaper;
          force = true;
        };
      };
    };
}
