{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      specialArgs = {
        inherit inputs;
        self = self.outPath;
      };

      legion = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          ./hosts/legion/default.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users.cdt = import ./hosts/legion/home.nix;
          }
        ];
      };
    in
    {
      nixosConfigurations = {
        legion = legion;
        nixos = legion;
      };

      homeConfigurations."cdt" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = specialArgs;
        modules = [ ./hosts/legion/home.nix ];
      };
    };
}
