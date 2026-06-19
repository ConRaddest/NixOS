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
          window_padding_width = 6;
          confirm_os_window_close = 0;
          enable_audio_bell = false;
          open_url_with = "${config.home.homeDirectory}/.config/kitty/open-url.sh";

          background = colors.base;
          foreground = colors.text;
          cursor = colors.text;
          cursor_text_color = colors.base;
          selection_background = colors.overlay;
          selection_foreground = colors.text;

          # Normal colors
          color0 = colors.black;
          color1 = colors.red;
          color2 = colors.green;
          color3 = colors.yellow;
          color4 = colors.blue;
          color5 = colors.purple;
          color6 = colors.teal;
          color7 = colors.white;

          # Bright colors
          color8 = colors.brightBlack;
          color9 = colors.brightRed;
          color10 = colors.brightGreen;
          color11 = colors.brightYellow;
          color12 = colors.brightBlue;
          color13 = colors.brightPurple;
          color14 = colors.brightCyan;
          color15 = colors.brightWhite;
        };
      };
    };
}
