{ ... }:

{
  flake.lib.homeModules.apps =
    { hostName, self, ... }:

    {
      imports = [
        "${self}/hosts/${hostName}/apps.nix"
        self.lib.homeModules.webapps
      ];

      xdg.desktopEntries = {
        # Hide upstream entry that has NoDisplay=true but still surfaces in launchers.
        uuctl = {
          name = "uuctl";
          exec = "uuctl";
          noDisplay = true;
          type = "Application";
        };
      };
    };
}
