{ ... }:

{
  flake.systemModules.audio =
    { ... }:

    {
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;

        wireplumber.extraConfig."10-audio-auto-switch" = {
          "wireplumber.settings" = {
            # Always choose the best currently available audio device instead of
            # pinning the default to a previously selected/stored device. This
            # makes newly connected headsets/speakers become default, and when
            # they disappear WirePlumber falls back to the integrated hardware.
            "node.restore-default-targets" = false;

            # Do not pin individual application streams to an old target. Keep
            # streams following the default sink/source when it changes.
            "node.stream.restore-target" = false;
            "linking.follow-default-target" = true;
          };
        };
      };
    };
}
