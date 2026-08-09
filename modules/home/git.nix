{ ... }:

{
  flake.lib.homeModules.git =
    { host, ... }:

    {
      programs.git = {
        enable = true;

        settings.user = {
          name = host.git.name;
          email = host.git.email;
        };
      };
    };
}
