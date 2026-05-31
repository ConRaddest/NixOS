{ font, colors, config, ... }:

{
  xdg.configFile."kitty/open-url.sh" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      url="$1"
      if [[ "$url" == file://* ]]; then
        code --goto "''${url#file://}"
      else
        xdg-open "$url"
      fi
    '';
  };

  programs.kitty = {
    enable = true;
    keybindings = {
      "shift+delete" = "copy_to_clipboard";
      "ctrl+insert" = "copy_to_clipboard";
      "shift+insert" = "paste_from_clipboard";
    };

    settings = {
      font_family               = font.mono;
      font_size                 = 12;
      window_padding_width      = 8;
      confirm_os_window_close   = 0;
      enable_audio_bell         = false;
      open_url_with             = "${config.home.homeDirectory}/.config/kitty/open-url.sh";

      background                = colors.bg;
      foreground                = colors.fg;
      cursor                    = colors.blue;
      cursor_text_color         = colors.bg;
      selection_background      = colors.bgAlt;
      selection_foreground      = colors.fg;

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
