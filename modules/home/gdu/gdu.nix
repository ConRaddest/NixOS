{ ... }:

{
  flake.lib.homeModules.gdu =
    {
      config,
      pkgs,
      ...
    }:

    let
      colors = config.nos.theme.colors;
    in
    {
      # Custom config below renders semantic colors directly.
      stylix.targets.gdu.enable = false;

      home.packages = [ pkgs.gdu ];

      xdg.configFile."gdu/gdu.yaml".source = pkgs.replaceVars ./gdu.yaml {
        inherit (colors) accent background foreground;
      };
    };
}
