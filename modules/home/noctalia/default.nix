{ inputs, ... }:

{
  flake.lib.homeModules.noctalia =
    {
      config,
      lib,
      ...
    }:

    let
      colors = config.nos.theme.colors;
      palette = config.lib.stylix.colors.withHashtag;
      ansi = {
        black = palette.base00;
        red = palette.base08;
        green = palette.base0B;
        yellow = palette.base0A;
        blue = palette.base0D;
        magenta = palette.base0E;
        cyan = palette.base0C;
        white = palette.base05;
      };
      terminal = {
        normal = ansi;
        bright = {
          black = palette.base03;
          red = palette.base08;
          green = palette.base0B;
          yellow = palette.base0A;
          blue = palette.base0D;
          magenta = palette.base0E;
          cyan = palette.base0C;
          white = palette.base07;
        };
        foreground = colors.foreground;
        background = colors.background;
        cursor = colors.primary;
        cursorText = colors.background;
        selectionFg = colors.highlight;
        selectionBg = colors.selection;
      };
      paletteMode = {
        mPrimary = colors.primary;
        mOnPrimary = colors.background;
        mSecondary = colors.secondary;
        mOnSecondary = colors.background;
        mTertiary = colors.info;
        mOnTertiary = colors.background;
        mError = colors.error;
        mOnError = colors.background;
        mSurface = colors.background;
        mOnSurface = colors.foreground;
        mSurfaceVariant = colors.surface;
        mOnSurfaceVariant = colors.highlight;
        mOutline = colors.border;
        mShadow = colors.background;
        mHover = colors.selection;
        mOnHover = colors.foreground;
        inherit terminal;
      };
      settings = lib.recursiveUpdate (builtins.fromTOML (builtins.readFile ./settings.toml)) {
        theme = {
          mode = config.nos.theme.polarity;
          source = "custom";
          custom_palette = "nixos";
        };
        wallpaper.enabled = false;
        widget.workspaces.font_family = config.stylix.fonts.monospace.name;
      };
    in
    {
      imports = [ inputs.noctalia.homeModules.default ];

      programs.noctalia = {
        enable = true;
        systemd.enable = true;
        inherit settings;
        customPalettes.nixos = {
          dark = paletteMode;
          light = paletteMode;
        };
      };
    };
}
