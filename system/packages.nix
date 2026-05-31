{ ... }:

{
  flake.systemModules.packages =
    { pkgs, ... }:

    {
      environment.systemPackages = with pkgs; [
        # color picker
        hyprpicker

        # polkit
        lxqt.lxqt-policykit

        # screenshot management
        grim
        slurp

        # notification lib
        libnotify

        # command line media player
        playerctl

        # device brightness
        brightnessctl

        # clipboard management
        cliphist
        wl-clipboard

        # reloading home manager
        home-manager
        # custom shell
        quickshell

        # wifi / bluetooth / volume ui
        bluetui
        impala
        wiremix
        # controls volume from cli
        pamixer

        # networking backend for impala
        iwd

        # windows vm
        qemu

        # passwords / ssh management
        _1password-gui
        _1password-cli

        # system packages
        pciutils
        usbutils
      ];
    };
}
