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
      # Force Qt file dialogs through xdg-desktop-portal so ZapZap uses the
      # configured system file chooser instead of Qt's built-in chooser.
      xdg.desktopEntries."com.rtosta.zapzap" = {
        name = "ZapZap";
        comment = "WhatsApp desktop application";
        exec = "env QT_QPA_PLATFORMTHEME=xdgdesktopportal zapzap %u";
        icon = "com.rtosta.zapzap";
        type = "Application";
        mimeType = [ "x-scheme-handler/whatsapp" ];
        categories = [
          "Network"
          "InstantMessaging"
        ];
      };

      # ZapZap stores mutable app state alongside preferences, so manage only
      # the theme key instead of replacing the whole config file.
      home.activation.configureZapZapTheme = config.lib.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "$(dirname "${configFile}")"
        ${pkgs.crudini}/bin/crudini --set "${configFile}" system theme dark
      '';
    };
}
