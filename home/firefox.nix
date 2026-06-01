{ ... }:

{
  flake.lib.homeModules.firefox =
    { ... }:

    {
      programs.firefox = {
        enable = true;
        profiles.default = {
          id = 0;
          isDefault = true;
          path = "td4m60gg.default";
          settings = {
            "media.webrtc.pipewire.enabled" = true;
          };
        };
      };
    };
}
