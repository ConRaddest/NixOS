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
        localsend
        nautilus
        slack
        steam
        teams-for-linux
        vlc
        vscode
        zapzap
      ];
    };
}
