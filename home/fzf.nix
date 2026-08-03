{ ... }:

{
  flake.lib.homeModules.fzf = { ... }: {
    programs.fzf = {
      enable = true;
      enableBashIntegration = true;
    };
  };
}
