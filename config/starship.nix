{ colors, ... }:

{
  programs.bash.enable = true;

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$character";

      character = {
        success_symbol = "[](bold ${colors.blue})";
        error_symbol = "[](bold ${colors.red})";
      };

      directory = {
        style = "bold ${colors.blue}";
        truncation_length = 3;
        truncate_to_repo = false;
        format = "[$path]($style) ";
      };

      git_branch = {
        symbol = " ";
        style = "bold ${colors.magenta}";
        format = "[$symbol$branch]($style) ";
      };

      git_status = {
        style = "bold ${colors.yellow}";
        format = "([$all_status$ahead_behind]($style) )";
      };
    };
  };
}
