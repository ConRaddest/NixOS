{ ... }:

{
  flake.lib.homeModules.starship =
    {
      self,
      colors,
      pkgs,
      ...
    }:

    let
      mkNosScript =
        name: script:
        pkgs.writeShellScriptBin name ''
          export NOS_DIR="$HOME/NixOS"
          export PATH="${pkgs.nixfmt}/bin:${pkgs.findutils}/bin:$PATH"
          exec ${pkgs.bash}/bin/bash ${script} "$@"
        '';

      nos-refresh = mkNosScript "nos-refresh" "${self}/config/starship/scripts/nos-refresh.sh";
      nos-build = mkNosScript "nos-build" "${self}/config/starship/scripts/nos-build.sh";
      nos-update = mkNosScript "nos-update" "${self}/config/starship/scripts/nos-update.sh";
      nos-check = mkNosScript "nos-check" "${self}/config/starship/scripts/nos-check.sh";
      nos-fmt = mkNosScript "nos-fmt" "${self}/config/starship/scripts/nos-fmt.sh";
      nos-theme = mkNosScript "nos-theme" "${self}/config/starship/scripts/nos-theme.sh";
    in
    {
      home.packages = [
        nos-refresh
        nos-build
        nos-update
        nos-check
        nos-fmt
        nos-theme
      ];

      home.sessionVariables = {
        QT_QPA_PLATFORM = "wayland";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      };

      programs.bash = {
        enable = true;
        shellAliases = {
          ls = "eza --icons";
          ll = "eza -la --icons";
          cd = "z";
        };
        initExtra = ''
          if [ -f "$HOME/NixOS/.env" ]; then
            source "$HOME/NixOS/.env"
          fi
        '';
      };

      programs.zoxide = {
        enable = true;
        enableBashIntegration = true;
      };

      programs.starship = {
        enable = true;
        enableBashIntegration = true;
      };

      xdg.configFile."starship.toml".text = ''
        add_newline = false
        format = "$directory$git_branch$character"

        [character]
        success_symbol = "[❯](${colors.primary})"
        error_symbol = "[❯](${colors.red})"

        [directory]
        style = "${colors.primary}"
        truncation_length = 3
        truncate_to_repo = false
        format = "[$path]($style) "

        [git_branch]
        symbol = ""
        style = "${colors.primary}"
        format = "[$symbol$branch]($style) "
      '';
    };
}
