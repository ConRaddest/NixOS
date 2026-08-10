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
        keep-derivations = false;
        keep-outputs = false;
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
