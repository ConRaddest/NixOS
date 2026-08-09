{ ... }:

{
  flake.lib.homeModules.audio =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        pamixer
        playerctl
        wiremix
      ];
    };
}
