{ ... }:

{
  flake.lib.homeModules.starship =
    { ... }:

    {
      programs.starship = {
        enable = true;
        enableFishIntegration = true;
      };

      xdg.configFile."matugen/templates/starship.toml".text = ''
        add_newline = false
        format = "$directory$git_branch$character"

        [character]
        success_symbol = "[❯]({{colors.primary.default.hex}})"
        error_symbol = "[❯]({{colors.error.default.hex}})"

        [directory]
        style = "{{colors.primary.default.hex}}"
        truncation_length = 3
        truncate_to_repo = false
        format = "[$path]($style) "

        [git_branch]
        symbol = ""
        style = "{{colors.primary.default.hex}}"
        format = "[$symbol$branch]($style) "
      '';
    };
}
