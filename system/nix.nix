{ ... }:

{
  flake.nixosModules.nix =
    { pkgs, ... }:

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

      # VS Code extensions such as MSSQL ship standard Linux executables.
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          icu
          krb5
          libunwind
        ];
      };
    };
}
