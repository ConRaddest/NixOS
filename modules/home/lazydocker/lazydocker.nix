{ ... }:

{
  flake.lib.homeModules.lazydocker =
    { config, pkgs, ... }:

    let
      colors = config.nos.theme.colors;
    in
    {
      xdg.desktopEntries.lazydocker = {
        name = "LazyDocker";
        comment = "Docker terminal UI";
        exec = "kitty --class lazy-docker --title lazy-docker -e lazydocker";
        icon = "docker";
        terminal = false;
        type = "Application";
        categories = [
          "Development"
          "System"
        ];
      };

      xdg.configFile."lazydocker/config.yml".text = ''
        gui:
          theme:
            activeBorderColor: ["${colors.primary}", "bold"]
            inactiveBorderColor: ["${colors.border}"]
            selectedLineBgColor: ["${colors.selection}"]
            optionsTextColor: ["${colors.primary}"]
            defaultFgColor: ["${colors.foreground}"]
      '';

      home.file = {
        # --- Docker ---
        ".local/share/icons/hicolor/scalable/apps/docker.svg".source = ./docker.svg;

      };

      home.packages = [ pkgs.lazydocker ];
    };
}
