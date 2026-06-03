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
            success_symbol = "[❯](${colors.primary})";
            error_symbol = "[❯](${colors.red})";
          };

          directory = {
            style = colors.primary;
            truncation_length = 3;
            truncate_to_repo = false;
            format = "[$path]($style) ";
          };

          git_branch = {
            symbol = "";
            style = colors.primary;
            format = "[$symbol$branch]($style) ";
          };
        };
      };
    };
}
