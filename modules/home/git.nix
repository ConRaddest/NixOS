{ ... }:

{
  flake.lib.homeModules.git =
    { ... }:

    {
      programs.git = {
        enable = true;

        settings.user = {
          name = "Connor du Toit";
          email = "connordutoit@gmail.com";
        };
      };
    };
}
