{ ... }:

{
  flake.lib.homeModules.starship =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      theme = config.nos.theme.colors;
    in
    {
      programs.starship = {
        enable = true;
        enableFishIntegration = false;

        settings = {
          add_newline = false;
          format = "$directory$character";

          directory = {
            format = "[$path](${theme.accent}) ";
            truncation_length = 3;
            truncation_symbol = "";
          };

          character = {
            success_symbol = "[❯](bold ${theme.accent})";
            error_symbol = "[❯](bold ${theme.accent})";
          };
        };
      };

      programs.fish.interactiveShellInit = lib.mkAfter ''
        if test "$TERM" != dumb
          set -gx STARSHIP_CONFIG ${config.xdg.configHome}/starship.toml

          ${pkgs.coreutils}/bin/env \
            PATH=${config.programs.starship.package}/bin \
            ${config.programs.starship.package}/bin/starship init fish --print-full-init | source
        end
      '';
    };
}
