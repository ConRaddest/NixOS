# !!---------------------------------------------------!!
# !!---------- AUTO-GENERATED: Do not edit! -----------!!
# !!---------------------------------------------------!!

{ ... }:

{
  flake.lib.homeModules.apps =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        audacity
        librewolf
        localsend
        slacky
        teams-for-linux
        trash-cli
        whatsie
      ];
    };
}
