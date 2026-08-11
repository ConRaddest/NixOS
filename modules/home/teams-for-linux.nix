{ ... }:

{
  flake.lib.homeModules.teamsForLinux =
    { ... }:

    {
      xdg.desktopEntries.teams-for-linux = {
        name = "Teams for Linux";
        comment = "Unofficial Microsoft Teams client";
        exec = "teams-for-linux --disable-gpu %U";
        icon = "teams-for-linux";
        type = "Application";
        mimeType = [ "x-scheme-handler/msteams" ];
        categories = [
          "Network"
          "InstantMessaging"
        ];
      };
    };
}
