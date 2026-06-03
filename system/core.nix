{ ... }:

{
  flake.systemModules.core =
    { pkgs, username, ... }:

    {
      boot.loader.systemd-boot.enable = true;
      boot.loader.efi.canTouchEfiVariables = true;

      services.greetd = {
        enable = true;
        settings.default_session = {
          command = "${pkgs.bash}/bin/bash --login -c 'uwsm start hyprland-uwsm.desktop'";
          user = username;
        };
      };
    };
}
