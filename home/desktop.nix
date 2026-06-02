{ ... }:

{
  flake.lib.homeModules.desktop =
    { pkgs, config, ... }:

    let
      webApps = builtins.fromJSON (builtins.readFile ../config/webapps/apps.json);
      appClass = app: "${app.id}-pwa";
      appIcon = app: ../config/webapps + "/${app.icon}";
      desktopEntryFor = app: {
        name = app.name;
        genericName = "${app.name} PWA";
        comment = "${app.name} running as a Chromium web app";
        exec = "${pkgs.chromium}/bin/chromium --user-data-dir=${config.home.homeDirectory}/.local/share/chromium-pwas/${app.id} --class=${appClass app} --name=${appClass app} --app=\"${app.url}\" --force-dark-mode --enable-features=WebContentsForceDark,WaylandWindowDecorations,WebRTCPipeWireCapturer,NativeNotifications,SystemNotifications --password-store=basic --ozone-platform-hint=auto --enable-native-notifications %U";
        icon = toString (appIcon app);
        terminal = false;
        settings.StartupWMClass = appClass app;
      };
      webAppDesktopEntries = builtins.listToAttrs (
        map (app: {
          name = "${app.id}-pwa";
          value = desktopEntryFor app;
        }) webApps
      );
      webAppProfileDirs = builtins.listToAttrs (
        map (app: {
          name = ".local/share/chromium-pwas/${app.id}/.keep";
          value.text = "";
        }) webApps
      );
    in
    {
      home.file = webAppProfileDirs;

      xdg.desktopEntries = webAppDesktopEntries // {
        uuctl = {
          name = "uuctl";
          exec = "uuctl";
          noDisplay = true;
        };
      };
    };
}
