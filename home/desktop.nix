{ ... }:

{
  flake.lib.homeModules.desktop =
    { ... }:

    {
      xdg.desktopEntries = {
        uuctl = {
          name = "uuctl";
          exec = "uuctl";
          noDisplay = true;
        };
      };
    };
}
