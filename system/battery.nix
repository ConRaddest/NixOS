{ ... }:

{
  flake.systemModules.battery =
    { pkgs, ... }:

    {
      boot.kernelParams = [ "mem_sleep_default=deep" ];

      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;

      # Laptop-specific power management.
      services.thermald.enable = true;

      services.logind.settings.Login = {
        HandlePowerKey = "ignore";
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        HandleLidSwitchDocked = "ignore";
      };

      services.udev.extraRules = ''
        ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver"
        ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance"
      '';

    };
}
