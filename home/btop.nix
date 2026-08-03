{ ... }:

{
  flake.lib.homeModules.btop =
    { ... }:

    {
      programs.btop = {
        enable = true;
        settings.vim_keys = true;
      };

      xdg.desktopEntries.btop = {
        name = "btop++";
        genericName = "System Monitor";
        comment = "Resource monitor for processor, memory, disks, network and processes";
        exec = "kitty --title performance-monitor -e btop";
        icon = "btop";
        terminal = false;
        type = "Application";
        categories = [
          "System"
          "Monitor"
        ];
      };
    };
}
