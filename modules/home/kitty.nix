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

      xdg.configFile."kitty/nvim-padding.py".text = ''
        import os
        import shlex

        neovim_windows = set()


        def is_neovim(cmdline):
            try:
                command = shlex.split(cmdline)
            except ValueError:
                command = cmdline.split()

            if not command:
                return False

            return os.path.basename(command[0]) in {"nvim", "vim", "vi"}


        def set_padding(boss, window, padding):
            boss.call_remote_control(
                window,
                (
                    "set-spacing",
                    f"--match=id:{window.id}",
                    f"padding={padding}",
                ),
            )


        def on_cmd_startstop(boss, window, data):
            if data["is_start"] and is_neovim(data["cmdline"]):
                neovim_windows.add(window.id)
                set_padding(boss, window, "0")
            elif not data["is_start"] and window.id in neovim_windows:
                neovim_windows.remove(window.id)
                set_padding(boss, window, "default")
      '';

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
