{ ... }:

{
  flake.nixosModules.fonts =
    { pkgs, ... }:

    {
      fonts.packages = with pkgs; [
        adwaita-fonts
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        nerd-fonts.jetbrains-mono
        font-awesome
      ];
    };
}
