{ ... }:

{
  flake.lib.homeModules.kitty =
    {
      font,
      config,
      pkgs,
      ...
    }:

    let
      kitty = pkgs.symlinkJoin {
        name = "kitty-cosmic";
        paths = [ pkgs.kitty ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram "$out/bin/kitty" \
            --run 'if [[ ":''${XDG_CURRENT_DESKTOP:-}:" == *:COSMIC:* ]]; then set -- --override background_opacity=0.80 --override background_blur=1 "$@"; fi'
        '';
      };
    in
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
        package = kitty;

        keybindings = {
          "shift+delete" = "copy_to_clipboard";
          "ctrl+insert" = "copy_to_clipboard";
          "shift+insert" = "paste_from_clipboard";
        };

        extraConfig = ''
          include dank-theme.conf
        '';

        settings = {
          font_family = font.mono;
          font_size = 12;
          window_padding_width = 6;
          hide_window_decorations = "yes";
          confirm_os_window_close = 0;
          enable_audio_bell = false;
          open_url_with = "${config.home.homeDirectory}/.config/kitty/open-url.sh";
        };
      };
    };
}
