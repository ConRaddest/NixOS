{ ... }:

{
  flake.lib.homeModules.firefox =
    { ... }:

    {
      home.file.".config/mozilla/firefox/td4m60gg.default/user.js".text = ''
        user_pref("media.webrtc.pipewire.enabled", true);
      '';
    }
;
}
