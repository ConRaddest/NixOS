{ ... }:

{
  flake.nixosModules.core =
    { pkgs, ... }:

    {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      environment.systemPackages = with pkgs; [
        pciutils
        usbutils
      ];
    };
}
