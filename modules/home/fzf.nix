{ ... }:

{
  flake.lib.homeModules.fzf =
    { config, lib, ... }:

    {
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
