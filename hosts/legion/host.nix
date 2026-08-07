{ self, inputs, ... }:

let
  # ============================================================
  # Host
  # ============================================================

  hostName = "legion";
  host = {
    system = "x86_64-linux";
    username = "cdt";
    fullName = "Connor du Toit";
    homeDirectory = "/home/cdt";
    flakeDirectory = "/home/cdt/NixOS";
    stateVersion = "26.05";
  };

  specialArgs = {
    inherit
      inputs
      self
      hostName
      font
      ;
    inherit (host)
      username
      fullName
      homeDirectory
      flakeDirectory
      stateVersion
      ;
  };

  pkgs = import inputs.nixpkgs {
    system = host.system;
    config.allowUnfree = true;
  };

  # ============================================================
  # Theme
  # ============================================================

  font = {
    system = "Adwaita Sans";
    size = 11;
    mono = "JetBrainsMono Nerd Font";
    monoSize = 10;
  };

  # ============================================================
  # Home
  # ============================================================

  homeConfig = {
    imports = [ self.lib.homeModules.home ];

    _module.args = { inherit font; };

    nos = {
      isNixOS = true;
      flakeDirectory = host.flakeDirectory;
    };

    home.username = host.username;
    home.homeDirectory = host.homeDirectory;
    home.stateVersion = host.stateVersion;

    programs.home-manager.enable = true;
  };
in
{
  # ============================================================
  # System modules
  # ============================================================

  flake.nixosModules.legionConfiguration =
    { stateVersion, ... }:
    {
      imports = [
        self.nixosModules.legionHardware

        self.nixosModules.core
        self.nixosModules.rsa
        self.nixosModules.networking
        self.nixosModules.nix
        self.nixosModules.security

        self.nixosModules.fonts
        self.nixosModules.hyprland
        self.nixosModules.portals

        self.nixosModules.bluetooth
        self.nixosModules.nvidia

        self.nixosModules.audio
        self.nixosModules.battery
        self.nixosModules.printing

        self.nixosModules.docker
        self.nixosModules.onepassword
      ];

      networking.hostName = hostName;
      system.stateVersion = stateVersion;
    };

  # ============================================================
  # Outputs
  # ============================================================

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
      modules = [ homeConfig ];
    };

    "${host.username}@${hostName}" = self.homeConfigurations.${host.username};
  };
}
