{ ... }:

{
  flake.nixosModules.battery =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    let
      setPowerProfile = pkgs.writeShellScript "set-power-profile" ''
        set -euo pipefail

        requested="$1"
        ppc=${pkgs.power-profiles-daemon}/bin/powerprofilesctl

        # power-profiles-daemon is D-Bus activated and can be briefly unavailable
        # during boot/resume/udev events. Wait a little, then silently skip if no
        # profiles are exposed yet rather than printing noisy TTY errors.
        for _ in $(seq 1 20); do
          if "$ppc" list 2>/dev/null | grep -q "^[*[:space:]]*$requested:"; then
            exec "$ppc" set "$requested"
          fi
          sleep 0.25
        done

        exit 0
      '';

      setCurrentPowerProfile = pkgs.writeShellScript "set-current-power-profile" ''
        set -euo pipefail

        if grep -qs 1 /sys/class/power_supply/AC*/online /sys/class/power_supply/ADP*/online; then
          exec ${setPowerProfile} performance
        else
          exec ${setPowerProfile} power-saver
        fi
      '';
    in
    {
      boot.kernelParams = lib.optional config.nos.hardware.deepSleep "mem_sleep_default=deep";

      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;

      services.thermald.enable = config.nos.hardware.thermald;

      # Hyprland owns power-key and lid-switch handling.
      services.logind.settings.Login = {
        HandlePowerKey = "ignore";
        HandleLidSwitch = "ignore";
        HandleLidSwitchExternalPower = "ignore";
        HandleLidSwitchDocked = "ignore";
      };

      powerManagement.resumeCommands = ''
        ${setCurrentPowerProfile} || true
      '';

      # Trigger systemd units from udev instead of running longer commands directly in udev.
      services.udev.extraRules = ''
        ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-profile-battery.service"
        ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-profile-ac.service"
      '';

      systemd.services.power-profile-battery = {
        description = "Set power profile when running on battery";
        after = [ "power-profiles-daemon.service" ];
        wants = [ "power-profiles-daemon.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${setPowerProfile} power-saver";
        };
      };

      systemd.services.power-profile-ac = {
        description = "Set power profile when running on AC power";
        after = [ "power-profiles-daemon.service" ];
        wants = [ "power-profiles-daemon.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${setPowerProfile} performance";
        };
      };
    };
}
