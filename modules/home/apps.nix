{ ... }:

{
  flake.lib.homeModules.apps =
    { hostName, self, ... }:

    {
      imports = [ "${self}/hosts/${hostName}/apps.nix" ];

      # Hide upstream entry that has NoDisplay=true but still surfaces in launchers.
      xdg.desktopEntries.uuctl = {
        name = "uuctl";
        exec = "uuctl";
        noDisplay = true;
        type = "Application";
      };
    };
}
