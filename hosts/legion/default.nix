{ self, inputs, ... }:

let
  hostName = "legion";
  host = {
    system = "x86_64-linux";
    username = "cdt";
    fullName = "Connor du Toit";
    homeDirectory = "/home/cdt";
    stateVersion = "26.05";
  };

  specialArgs = {
    inherit inputs self hostName;
    inherit (host) username fullName homeDirectory stateVersion;
  };

  pkgs = import inputs.nixpkgs {
    system = host.system;
    config.allowUnfree = true;
  };
in
{
  flake.nixosModules.homeManager =
    { ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-backup";
        extraSpecialArgs = specialArgs;
        users.${host.username} = self.lib.homeModules.profile;
      };
    };

  flake.nixosModules.legionConfiguration =
    { stateVersion, ... }:
    {
      imports = [
        self.nixosModules.legionHardware

        self.nixosModules.boot
        self.nixosModules.locale
        self.nixosModules.networking
        self.nixosModules.nix
        self.nixosModules.users

        self.nixosModules.fonts
        self.nixosModules.greetd
        self.nixosModules.hyprland
        self.nixosModules.portals

        self.nixosModules.bluetooth
        self.nixosModules.nvidia

        self.nixosModules.audio
        self.nixosModules.power
        self.nixosModules.printing

        self.nixosModules.docker
        self.nixosModules.packages
        self.nixosModules.homeManager
      ];

      networking.hostName = hostName;
      system.stateVersion = stateVersion;
    };

  flake.nixosConfigurations = {
    ${hostName} = inputs.nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      system = host.system;
      modules = [ self.nixosModules.legionConfiguration ];
    };

    nixos = self.nixosConfigurations.${hostName};
  };

  flake.homeConfigurations = {
    ${host.username} = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = specialArgs;
      modules = [ self.lib.homeModules.profile ];
    };

    "${host.username}@${hostName}" = self.homeConfigurations.${host.username};
  };
}
