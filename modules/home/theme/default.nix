{ inputs, ... }:

{
  flake.lib.homeModules.theme =
    {
      font,
      pkgs,
      ...
    }:

    {
      imports = [ inputs.stylix.homeModules.stylix ];

      stylix = {
        enable = true;
        autoEnable = true;
        polarity = "dark";
        image = ./sunset-lake.png;
        imageScalingMode = "fill";
        base16Scheme = ./tokyo-night-mauve.yaml;

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

        targets = {
          firefox = {
            profileNames = [ "default" ];
            firefoxGnomeTheme.enable = true;
          };

          # Hyprland uses Lua config, so its colors are applied by our Lua
          # adapter instead of Stylix's generated Hyprland config.
          hyprland.enable = false;

          # Existing GDU behavior and colors share one YAML file.
          gdu.enable = false;

          # Custom Yazi layout, separators, icons, and file rules consume the
          # Stylix palette directly.
          yazi.enable = false;

          gtk.enable = true;
          qt.enable = true;
        };
      };

      home.file."Pictures/Wallpapers/sunset-lake.png" = {
        source = ./sunset-lake.png;
        force = true;
      };
    };
}
