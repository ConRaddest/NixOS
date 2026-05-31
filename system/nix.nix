{ ... }:

{
  flake.systemModules.nix =
    { ... }:

    {
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 10d";
      };

      nixpkgs.config.allowUnfree = true;
    };
}
