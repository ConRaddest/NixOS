{ ... }:

{
  flake.nixosModules.battery =
    { pkgs, ... }:

    {
      boot.kernelParams = [ "mem_sleep_default=deep" ];

      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;

      environment.systemPackages = [ pkgs.brightnessctl ];

      # Laptop-specific power management.
      services.thermald.enable = true;

      services.logind.settings.Login = {
        HandlePowerKey = "ignore";
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        HandleLidSwitchDocked = "ignore";
      };

      # Trigger systemd units from udev instead of running longer commands directly in udev.
      services.udev.extraRules = ''
        ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-profile-battery.service"
        ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-profile-ac.service"
      '';

      systemd.services.power-profile-battery = {
        description = "Set power profile when running on battery";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver";
        };
      };

      systemd.services.power-profile-ac = {
        description = "Set power profile when running on AC power";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance";
        };
      };

    };
}
