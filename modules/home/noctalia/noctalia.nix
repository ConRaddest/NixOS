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
      terminal = {
        normal = {
          black = colors.background;
          red = colors.red;
          green = colors.green;
          yellow = colors.yellow;
          blue = colors.blue;
          magenta = colors.magenta;
          cyan = colors.cyan;
          white = colors.foreground;
        };
        bright = {
          black = colors.muted;
          red = colors.bright_red;
          green = colors.bright_green;
          yellow = colors.bright_yellow;
          blue = colors.bright_blue;
          magenta = colors.bright_magenta;
          cyan = colors.bright_cyan;
          white = colors.bright_foreground;
        };
        foreground = colors.foreground;
        background = colors.background;
        cursor = colors.accent;
        cursorText = colors.background;
        selectionFg = colors.selection_foreground;
        selectionBg = colors.selection;
      };
      paletteMode = {
        mPrimary = colors.accent;
        mOnPrimary = colors.background;
        mSecondary = colors.magenta;
        mOnSecondary = colors.background;
        mTertiary = colors.cyan;
        mOnTertiary = colors.background;
        mError = colors.red;
        mOnError = colors.background;
        mSurface = colors.background;
        mOnSurface = colors.foreground;
        mSurfaceVariant = colors.dark_background;
        mOnSurfaceVariant = colors.bright_foreground;
        mOutline = colors.muted;
        mShadow = colors.background;
        mHover = colors.selection;
        mOnHover = colors.foreground;
        inherit terminal;
      };
      settings = lib.recursiveUpdate (builtins.fromTOML (builtins.readFile ./settings.toml)) {
        theme = {
          mode = config.nos.theme.mode;
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
