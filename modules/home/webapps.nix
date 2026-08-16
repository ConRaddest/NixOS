{ ... }:

{
  flake.lib.homeModules.webapps =
    {
      config,
      hostName,
      lib,
      pkgs,
      self,
      ...
    }:

    let
      webApps = import "${self}/hosts/${hostName}/webapps.nix";
      colorSchemeFlags = lib.optionalString (config.nos.theme.mode == "dark") "--force-dark-mode";
    in
    {
      xdg.desktopEntries = builtins.listToAttrs (
        map (
          app:
          let
            profileFlag = lib.optionalString (app.private or false
            ) "--user-data-dir=${config.xdg.dataHome}/chromium-webapps/${app.id} ";
          in
          lib.nameValuePair app.id {
            inherit (app) name;
            comment = "${app.name} web app";
            exec = ''${pkgs.chromium}/bin/chromium ${profileFlag}--app="${
              lib.replaceStrings [ "%" "\"" ] [ "%%" "\\\"" ] app.url
            }" ${colorSchemeFlags} --hide-scrollbars --auto-select-desktop-capture-source="Entire screen" --use-fake-ui-for-media-stream --test-type'';
            icon = "${pkgs.fetchurl {
              url = app.iconUrl;
              hash = app.iconHash;
              name = "${app.id}-icon.png";
            }}";
            categories = [ "Network" ];
            terminal = false;
            type = "Application";
          }
        ) webApps
      );
    };
}
