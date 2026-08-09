{ ... }:

{
  flake.nixosModules.docker =
    { ... }:

    {
      virtualisation.docker.enable = true;

      # Required by Docker workloads and Windows VM networking.
      boot.kernelModules = [ "tun" ];
    };
}
