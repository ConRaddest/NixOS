{ ... }:

{
  flake.nixosModules.greetd =
    { pkgs, username, ... }:

    {
      services.greetd = {
        enable = true;
        settings.default_session = {
          command = "${pkgs.bash}/bin/bash --login -c 'uwsm start hyprland-uwsm.desktop'";
          user = username;
        };
      };
    }
;
}
