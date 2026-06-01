{ ... }:

{
  flake.lib.homeModules.kitty =
    {
      font,
      colors,
      config,
      ...
    }:

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
          font_family = font.mono;
          font_size = 12;
          window_padding_width = 8;
          confirm_os_window_close = 0;
          enable_audio_bell = false;
          open_url_with = "${config.home.homeDirectory}/.config/kitty/open-url.sh";

          background = colors.bg;
          foreground = colors.terminal.foreground;
          cursor = colors.terminal.cursor;
          cursor_text_color = colors.bg;
          selection_background = colors.terminal.selectionBg;
          selection_foreground = colors.terminal.selectionFg;

          # Normal colors
          color0 = colors.terminal.c0;
          color1 = colors.terminal.c1;
          color2 = colors.terminal.c2;
          color3 = colors.terminal.c3;
          color4 = colors.terminal.c4;
          color5 = colors.terminal.c5;
          color6 = colors.terminal.c6;
          color7 = colors.terminal.c7;

          # Bright colors
          color8 = colors.terminal.c8;
          color9 = colors.terminal.c9;
          color10 = colors.terminal.c10;
          color11 = colors.terminal.c11;
          color12 = colors.terminal.c12;
          color13 = colors.terminal.c13;
          color14 = colors.terminal.c14;
          color15 = colors.terminal.c15;
        };
      };
    };
}
