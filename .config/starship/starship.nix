{ colors, pkgs, ... }:

let
  nos-refresh = pkgs.writeShellScriptBin "nos-refresh" (builtins.readFile ./scripts/nos-refresh.sh);
  nos-build   = pkgs.writeShellScriptBin "nos-build"   (builtins.readFile ./scripts/nos-build.sh);
  nos-update  = pkgs.writeShellScriptBin "nos-update"  (builtins.readFile ./scripts/nos-update.sh);
  nos-check   = pkgs.writeShellScriptBin "nos-check"   (builtins.readFile ./scripts/nos-check.sh);
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
