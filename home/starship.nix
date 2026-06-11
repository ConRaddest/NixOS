{ ... }:

{
  flake.lib.homeModules.starship =
    { colors, ... }:

    {
      programs.starship = {
        enable = true;
        enableBashIntegration = true;
        settings = {
          add_newline = false;
          format = "$directory$git_branch$character";

          character = {
            success_symbol = "[❯](${colors.accent})";
            error_symbol = "[❯](${colors.red})";
          };

          directory = {
            style = colors.accent;
            truncation_length = 3;
            truncate_to_repo = false;
            format = "[$path]($style) ";
          };

          git_branch = {
            symbol = "";
            style = colors.accent;
            format = "[$symbol$branch]($style) ";
          };
        };
      };
    };
}
