{ ... }:

{
  flake.systemModules.packages =
    { pkgs, ... }:

    {
      environment.systemPackages = with pkgs; [
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
        home-manager
        quickshell
        bluetui
        impala
        iwd
        qemu
        _1password-gui
        _1password-cli
        pciutils
        usbutils
      ];
    };
}
