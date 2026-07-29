{ ... }:

{
  flake.lib.homeModules.zapzap =
    {
      config,
      pkgs,
      ...
    }:

    let
      configFile = "${config.xdg.configHome}/ZapZap/ZapZap.conf";
    in
    {
      # ZapZap stores mutable app state alongside preferences, so manage only
      # the theme key instead of replacing the whole config file.
      home.activation.configureZapZapTheme = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$(dirname "${configFile}")"
        ${pkgs.crudini}/bin/crudini --set "${configFile}" system theme dark
      '';
    };
}
