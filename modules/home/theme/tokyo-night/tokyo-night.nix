{ ... }:

{
  flake.lib.homeModules.themeTokyoNight =
    { ... }:

    {
      nos.theme = {
        name = "Tokyo Night Mauve";
        polarity = "dark";
        wallpaper = ./wallpaper.png;

        # Keep Base16 slots aligned with their standard UI and syntax meanings.
        palette = {
          base00 = "#1a1b26"; # Default background
          base01 = "#16161e"; # Alternate background
          base02 = "#24283b"; # Selection background
          base03 = "#414868"; # Comments, invisibles, and borders
          base04 = "#565f89"; # Dark foreground and inactive text
          base05 = "#a9b1d6"; # Default foreground
          base06 = "#c0caf5"; # Light foreground
          base07 = "#d5d6db"; # Light background
          base08 = "#f1738c"; # Red: errors and variables
          base09 = "#f3a170"; # Orange: integers and constants
          base0A = "#dfaf69"; # Yellow: warnings and types
          base0B = "#9dc672"; # Green: success and strings
          base0C = "#8dcbef"; # Cyan: regex and support
          base0D = "#7ba2f6"; # Blue: functions and headings
          base0E = "#bb9af7"; # Purple: keywords and control flow
          base0F = "#c53b53"; # Deprecated and embedded-language tags
        };

        # Theme accents are semantic colors, not Base16 syntax slots.
        extraColors = {
          accent = "#cba6f7";
          accentDark = "#9d7cd8";
        };

        # Preserve existing semantic theme colors after standardizing Base16.
        roles = {
          background = "base00";
          surface = "base01";
          selection = "base02";
          border = "base03";
          muted = "base04";
          foreground = "base05";
          highlight = "base06";
          accent = "accent";
          error = "base08";
          orange = "base09";
          warning = "base0A";
          blue = "base0D";
          success = "base0B";
          info = "base0C";
          primary = "base0E";
          secondary = "base0E";
          accentDark = "accentDark";
        };
      };
    };
}
