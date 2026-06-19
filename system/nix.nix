{ ... }:

{
  flake.nixosModules.nix =
    { ... }:

    {
      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
        keep-derivations = true;
        keep-outputs = true;
        trusted-users = [
          "root"
          "@wheel"
        ];
      };

      nix.gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 10d";
      };

      nixpkgs.config.allowUnfree = true;
    };
}
