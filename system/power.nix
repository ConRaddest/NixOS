{ ... }:

{
  flake.systemModules.power =
    { pkgs, ... }:

    {
      # Prefer real S3 suspend over s2idle/modern-standby. s2idle can leave
      # laptop LEDs/fans looking "awake" and is easier for devices to wake.
      boot.kernelParams = [ "mem_sleep_default=deep" ];

      # Avoid common spurious wake sources. Keep the power button/lid and RTC
      # available, but prevent USB and the Ethernet PCIe root port from waking
      # the laptop immediately after suspend.
      systemd.services.disable-spurious-wakeup-sources = {
        description = "Disable spurious ACPI wakeup sources";
        wantedBy = [ "multi-user.target" ];
        after = [ "sysinit.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = pkgs.writeShellScript "disable-spurious-wakeup-sources" ''
            set -eu

            disable_acpi_wakeup() {
              device="$1"
              if grep -q "^$device[[:space:]].*\*enabled" /proc/acpi/wakeup; then
                echo "$device" > /proc/acpi/wakeup
              fi
            }

            # XHC: USB controller. Prevent mouse/keyboard/dongle noise waking suspend.
            disable_acpi_wakeup XHC

            # RP14: PCIe root port for the Realtek Ethernet controller.
            disable_acpi_wakeup RP14

            # Also disable wakeup through the matching sysfs nodes when present.
            for node in \
              /sys/bus/pci/devices/0000:00:14.0/power/wakeup \
              /sys/bus/pci/devices/0000:00:1d.5/power/wakeup \
              /sys/bus/pci/devices/0000:07:00.0/power/wakeup
            do
              if [ -w "$node" ]; then
                echo disabled > "$node"
              fi
            done
          '';
        };
      };

      services.power-profiles-daemon.enable = true;
      services.upower.enable = true;
    };
}
