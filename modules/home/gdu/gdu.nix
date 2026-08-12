{ ... }:

{
  flake.lib.homeModules.gdu =
    {
      config,
      host,
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
        inherit (colors) background foreground primary;
        maxCores = toString host.gduMaxCores;
      };
    };
}
