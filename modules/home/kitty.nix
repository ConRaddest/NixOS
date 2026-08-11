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
        package = kittyWithoutSystemdScopes;

        keybindings = {
          "shift+delete" = "copy_to_clipboard";
          "ctrl+insert" = "copy_to_clipboard";
          "shift+insert" = "paste_from_clipboard";
        };

        settings = {
          window_padding_width = 6;
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
