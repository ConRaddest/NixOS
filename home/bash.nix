{ ... }:

{
  flake.lib.homeModules.bash =
    {
      self,
      pkgs,
      flakeDirectory,
      ...
    }:

    let
      mkNosScript =
        name: script:
        pkgs.writeShellScriptBin name ''
          export NOS_DIR="${flakeDirectory}"
          export PATH="${pkgs.home-manager}/bin:${pkgs.nixfmt}/bin:${pkgs.findutils}/bin:${pkgs.imagemagick}/bin:$PATH"
          exec ${pkgs.bash}/bin/bash ${script} "$@"
        '';

      nos-refresh = mkNosScript "nos-refresh" "${self}/scripts/system/nos-refresh.sh";
      nos-build = mkNosScript "nos-build" "${self}/scripts/system/nos-build.sh";
      nos-update = mkNosScript "nos-update" "${self}/scripts/system/nos-update.sh";
      nos-check = mkNosScript "nos-check" "${self}/scripts/system/nos-check.sh";
      nos-theme = mkNosScript "nos-theme" "${self}/scripts/system/nos-theme.sh";
      nos-install = mkNosScript "nos-install" "${self}/scripts/system/nos-install.sh";
      nos-remove = mkNosScript "nos-remove" "${self}/scripts/system/nos-remove.sh";

      nos-fonts = pkgs.writeShellScriptBin "nos-fonts" ''
        exec ${pkgs.fontconfig}/bin/fc-list : family | sort -u
      '';

      nos-mono-fonts = pkgs.writeShellScriptBin "nos-mono-fonts" ''
        exec ${pkgs.fontconfig}/bin/fc-list ':spacing=mono' family | sort -u
      '';

    in
    {
      home.sessionVariables.NOS_DIR = flakeDirectory;

      programs.bash = {
        enable = true;
        shellAliases = {
          ls = "eza --icons";
          ll = "eza -la --icons";
          cd = "z";
          ff = "fastfetch";
          startw = "uwsm start hyprland-uwsm.desktop";
        };
        profileExtra = ''
          # On the first boot tty, enter Hyprland automatically. Other TTYs
          # remain normal rescue consoles: Ctrl+Alt+F2/F3 and log in there.
          # To disable this from a rescue TTY: mkdir -p ~/.cache && touch ~/.cache/nos-disable-autostart
          if [[ -z "''${DISPLAY:-}" && -z "''${WAYLAND_DISPLAY:-}" && "$(tty)" == /dev/tty1 && ! -e "$HOME/.cache/nos-disable-autostart" ]]; then
            exec uwsm start hyprland-uwsm.desktop
          fi
        '';

        initExtra = ''
          if [ -f "${flakeDirectory}/.env" ]; then
            source "${flakeDirectory}/.env"
          fi

          # Show the terminal rice header once for each new interactive shell.
          # Use a shell-local marker so inherited environment variables cannot
          # suppress fastfetch in newly opened terminals.
          if [[ $- == *i* ]] && [ -z "''${__NOS_FASTFETCH_SHOWN:-}" ]; then
            __NOS_FASTFETCH_SHOWN=1
            if command -v fastfetch >/dev/null 2>&1; then
              # Prevent terminal reflow from wrapping the header into a jumble
              # when resizing from a wide terminal to a narrow one.
              tput rmam 2>/dev/null || true
              fastfetch
              tput smam 2>/dev/null || true
            fi
          fi
        '';
      };

      programs.zoxide = {
        enable = true;
        enableBashIntegration = true;
      };

      home.packages = with pkgs; [
        nos-refresh
        nos-build
        nos-update
        nos-check
        nos-theme
        nos-install
        nos-remove
        nos-fonts
        nos-mono-fonts

        # cli utilities
        eza # better ls
        jq # json cli proccessor
        nix-search-cli # search nix packages
        tldr # command summaries
        tree # folder
        unzip # unzip files
      ];

      programs.kitty.shellIntegration.enableBashIntegration = true;
    };
}
