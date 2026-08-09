{ ... }:

{
  flake.lib.homeModules.fzf =
    { ... }:

    {
      programs.fzf = {
        enable = true;
        enableFishIntegration = true;
      };
    };
}
