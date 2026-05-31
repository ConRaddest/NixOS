{ ... }:

{
  flake.systemModules.docker =
    { ... }:

    {
      virtualisation.docker.enable = true;
    };
}
