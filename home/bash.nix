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
          export PATH="${pkgs.nixfmt}/bin:${pkgs.findutils}/bin:${pkgs.imagemagick}/bin:$PATH"
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
