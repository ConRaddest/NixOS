{ ... }:

{
  flake.lib.homeModules.kitty =
    {
      config,
      pkgs,
      ...
    }:

    let
      kittyWithoutSystemdScopes = pkgs.kitty.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace kitty/child.py \
            --replace-fail \
              "fast_data_types.systemd_move_pid_into_new_scope(pid, f'kitty-{ppid}-{self.id}.scope', f'kitty child process: {pid} launched by: {ppid}')" \
              "raise NotImplementedError"
        '';
      });
      colors = config.nos.theme.colors;
    in
    {
      # Preserve full canonical ANSI palette beyond Base16 mapping.
      stylix.targets.kitty.enable = false;

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

      xdg.configFile."kitty/nvim-padding.py".source = ./nvim-padding.py;

      programs.kitty = {
        enable = true;
        package = kittyWithoutSystemdScopes;

        keybindings = {
          "ctrl+insert" = "copy_to_clipboard";
          "shift+insert" = "paste_from_clipboard";
          # "super+c" = "copy_to_clipboard";
          # "super+v" = "paste_from_clipboard";
          "shift+delete" = "copy_to_clipboard";
          "ctrl+shift+f12" = "new_os_window_with_cwd";
        };

        settings = {
          font_family = config.stylix.fonts.monospace.name;
          font_size = config.stylix.fonts.sizes.terminal;
          foreground = colors.foreground;
          background = colors.background;
          selection_foreground = colors.selection_foreground;
          selection_background = colors.selection_background;
          cursor = colors.bright_foreground;
          cursor_text_color = colors.background;
          active_border_color = colors.accent;
          active_tab_background = colors.accent;
          color0 = colors.background;
          color1 = colors.red;
          color2 = colors.green;
          color3 = colors.yellow;
          color4 = colors.blue;
          color5 = colors.magenta;
          color6 = colors.cyan;
          color7 = colors.foreground;
          color8 = colors.muted;
          color9 = colors.bright_red;
          color10 = colors.bright_green;
          color11 = colors.bright_yellow;
          color12 = colors.bright_blue;
          color13 = colors.bright_magenta;
          color14 = colors.bright_cyan;
          color15 = colors.bright_foreground;
          window_padding_width = 6;
          placement_strategy = "top-left";
          watcher = "nvim-padding.py";
          hide_window_decorations = "yes";
          confirm_os_window_close = 0;
          enable_audio_bell = false;
          cursor_trail = 50;
          cursor_trail_decay = "0.08 0.25";
          cursor_trail_start_threshold = 2;
          open_url_with = "${config.home.homeDirectory}/.config/kitty/open-url.sh";
        };
      };
    };
}
