{ colors, pkgs, configDir, ... }:

let
  mkNosScript = name: script:
    pkgs.writeShellScriptBin name ''
      export OS_CONFIG_DIR=${pkgs.lib.escapeShellArg configDir}
      exec ${pkgs.bash}/bin/bash ${script} "$@"
    '';

  nos-refresh = mkNosScript "nos-refresh" ../config/starship/scripts/nos-refresh.sh;
  nos-build   = mkNosScript "nos-build"   ../config/starship/scripts/nos-build.sh;
  nos-update  = mkNosScript "nos-update"  ../config/starship/scripts/nos-update.sh;
  nos-check   = mkNosScript "nos-check"   ../config/starship/scripts/nos-check.sh;
in
{
  home.packages = [
    nos-refresh
    nos-build
    nos-update
    nos-check
  ];

  programs.bash = {
    enable = true;
    shellAliases = {
      ls  = "eza --icons";
      ll  = "eza -la --icons";
      cd  = "z";
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
}
