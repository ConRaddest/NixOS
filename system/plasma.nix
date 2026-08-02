{ ... }:

{
  flake.nixosModules.plasma =
    { ... }:

    {
      services.desktopManager.plasma6.enable = true;
    };
}
