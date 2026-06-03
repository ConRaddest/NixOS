{ ... }:

{
  flake.systemModules.packages =
    {
      pkgs,
      ...
    }:

    {
      environment.systemPackages = with pkgs; [
        # color picker
        hyprpicker

        # polkit
        hyprpolkitagent

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

        # home manager
        home-manager
        # custom shell
        quickshell

        # bluetooth
        bluetui

        # network
        impala
        iwd

        # audio
        wiremix
        pamixer

        # windows vm
        qemu

        # system packages
        pciutils
        usbutils

        # trash support
        gvfs
      ];
    };
}
