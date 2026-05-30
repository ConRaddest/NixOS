{ colors, ... }:

{
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
}
