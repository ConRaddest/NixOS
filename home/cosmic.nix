{ ... }:

{
  flake.lib.homeModules.cosmic =
    { ... }:

    {
      xdg.configFile."cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom" = {
        force = true;
        text = ''
          {
              (
                  modifiers: [Super],
              ): Disable,
              (
                  modifiers: [Super],
                  key: "space",
              ): System(Launcher),
              (
                  modifiers: [Super],
                  key: "Return",
                  description: Some("Kitty"),
              ): Spawn("kitty"),
              (
                  modifiers: [Super],
                  key: "w",
              ): Close,
          }
        '';
      };
    };
}
