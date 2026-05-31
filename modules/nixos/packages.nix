{ ... }:

{
  flake.nixosModules.packages =
    { pkgs, ... }:

    {
      environment.systemPackages = with pkgs; [
        # Hyprland utilities / desktop integration
        hyprpicker
        lxqt.lxqt-policykit
        grim
        slurp
        wl-clipboard
        pamixer
        wiremix
        libnotify
        playerctl
        brightnessctl
        cliphist

        # Shell / system integration
        home-manager
        quickshell

        # Bluetooth / Wi-Fi
        bluetui
        impala
        iwd

        # Virtualisation
        qemu

        # Secrets
        _1password-gui
        _1password-cli

        # System tools
        pciutils
        usbutils
      ];
    }
;
}
