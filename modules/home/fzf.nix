{ ... }:

{
  flake.lib.homeModules.fzf =
    { config, lib, ... }:

    {
      stylix.targets.fzf.colors.override.withHashtag = {
        base01 = config.nos.theme.colors.selection;
        base04 = config.nos.theme.colors.foreground;
        base07 = config.nos.theme.colors.bright_foreground;
        base0A = config.nos.theme.colors.accent;
        base0C = config.nos.theme.colors.accent;
        base0D = config.nos.theme.colors.accent;
      };

      programs.fzf = {
        enable = true;
        enableFishIntegration = true;
      };

      # Session variables inherited by UWSM do not change during activation.
      # Set FZF colors in systemd and every new Fish shell as well.
      systemd.user.sessionVariables.FZF_DEFAULT_OPTS = config.home.sessionVariables.FZF_DEFAULT_OPTS;
      programs.fish.interactiveShellInit = lib.mkAfter ''
        set -gx FZF_DEFAULT_OPTS ${lib.escapeShellArg config.home.sessionVariables.FZF_DEFAULT_OPTS}
      '';
    };
}
