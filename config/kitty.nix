{ font, colors, ... }:

{
  programs.kitty = {
    enable = true;
    settings = {
      font_family = font.mono;
      font_size = font.monoSize;
      window_padding_width = 8;
      confirm_os_window_close = 0;
      enable_audio_bell = false;

      background            = colors.bg;
      foreground            = colors.fg;
      cursor                = colors.blue;
      cursor_text_color     = colors.bg;
      selection_background  = colors.bgAlt;
      selection_foreground  = colors.fg;

      # Normal colors
      color0  = colors.bgDark;
      color1  = colors.red;
      color2  = colors.green;
      color3  = colors.yellow;
      color4  = colors.blue;
      color5  = colors.magenta;
      color6  = colors.cyan;
      color7  = colors.fgDark;

      # Bright colors
      color8  = colors.black;
      color9  = colors.red;
      color10 = colors.teal;
      color11 = colors.orange;
      color12 = colors.blue;
      color13 = colors.purple;
      color14 = colors.cyan;
      color15 = colors.fg;
    };
  };
}
