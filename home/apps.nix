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
        drawio
        gimp
        libreoffice
        librewolf
        localsend
        slack
        teams-for-linux
        trash-cli
        vlc
        zapzap
      ];
    };
}
