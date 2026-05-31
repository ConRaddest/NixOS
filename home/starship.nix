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
          export NOS_DIR="$HOME/.local/nos"
          export PATH="${pkgs.nixfmt}/bin:${pkgs.findutils}/bin:$PATH"
          exec ${pkgs.bash}/bin/bash ${script} "$@"
        '';

      nos-refresh = mkNosScript "nos-refresh" "${self}/config/starship/scripts/nos-refresh.sh";
      nos-build = mkNosScript "nos-build" "${self}/config/starship/scripts/nos-build.sh";
      nos-update = mkNosScript "nos-update" "${self}/config/starship/scripts/nos-update.sh";
      nos-check = mkNosScript "nos-check" "${self}/config/starship/scripts/nos-check.sh";
      nos-fmt = mkNosScript "nos-fmt" "${self}/config/starship/scripts/nos-fmt.sh";
    in
    {
      home.packages = [
        nos-refresh
        nos-build
        nos-update
        nos-check
        nos-fmt
      ];

      programs.bash = {
        enable = true;
        shellAliases = {
          ls = "eza --icons";
          ll = "eza -la --icons";
          cd = "z";
        };
      };

      programs.zoxide = {
        enable = true;
        enableBashIntegration = true;
      };

      programs.starship = {
        enable = true;
        enableBashIntegration = true;

        settings = {
          add_newline = false;
          format = "$directory$git_branch$character";

          character = {
            success_symbol = "[❯](${colors.blue})";
            error_symbol = "[❯](${colors.red})";
          };

          directory = {
            style = "${colors.blue}";
            truncation_length = 3;
            truncate_to_repo = false;
            format = "[$path]($style) ";
          };

          git_branch = {
            symbol = "";
            style = "${colors.blue}";
            format = "[$symbol$branch]($style) ";
          };
        };
      };
    };
}
