{ ... }:

{
  flake.lib.homeModules.bash =
    {
      self,
      pkgs,
      ...
    }:

    let
      mkNosScript =
        name: script:
        pkgs.writeShellScriptBin name ''
          export NOS_DIR="$HOME/NixOS"
          export PATH="${pkgs.home-manager}/bin:${pkgs.nixfmt}/bin:${pkgs.findutils}/bin:${pkgs.imagemagick}/bin:$PATH"
          exec ${pkgs.bash}/bin/bash ${script} "$@"
        '';

      nos-refresh = mkNosScript "nos-refresh" "${self}/scripts/system/nos-refresh.sh";
      nos-build = mkNosScript "nos-build" "${self}/scripts/system/nos-build.sh";
      nos-update = mkNosScript "nos-update" "${self}/scripts/system/nos-update.sh";
      nos-check = mkNosScript "nos-check" "${self}/scripts/system/nos-check.sh";
      nos-theme = mkNosScript "nos-theme" "${self}/scripts/system/nos-theme.sh";
    in
    {
      programs.bash = {
        enable = true;
        shellAliases = {
          ls = "eza --icons";
          ll = "eza -la --icons";
          cd = "z";
          ff = "fastfetch";
          startw = "uwsm start hyprland-uwsm.desktop";
        };
        initExtra = ''
          if [ -f "$HOME/NixOS/.env" ]; then
            source "$HOME/NixOS/.env"
          fi

          # Show the terminal rice header once for each new interactive terminal.
          if [[ $- == *i* ]] && [ -z "''${FASTFETCH_SHOWN:-}" ]; then
            export FASTFETCH_SHOWN=1
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

      home.packages = [
        nos-refresh
        nos-build
        nos-update
        nos-check
        nos-theme
      ];

      programs.kitty.shellIntegration.enableBashIntegration = true;
    };
}
