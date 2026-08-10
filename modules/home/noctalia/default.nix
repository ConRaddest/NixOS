{ inputs, ... }:

{
  flake.lib.homeModules.noctalia =
    { ... }:

    {
      imports = [ inputs.noctalia.homeModules.default ];

      programs.noctalia = {
        enable = true;
        systemd.enable = true;
        settings = ./settings.toml;
      };
    };
}
