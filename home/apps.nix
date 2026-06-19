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
        localsend
        slacky
        teams-for-linux
        trash-cli
        whatsie
      ];
    };
}
