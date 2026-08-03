{ self, inputs, ... }:

let
  # ============================================================
  # Host
  # ============================================================

  hostName = "legion";
  host = {
    system = "x86_64-linux";
    desktopShell = "dms"; # Supported: "dms", "none"
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
      desktopShell
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

  colors = import "${self}/config/palette.nix";

  # ============================================================
  # Home
  # ============================================================

  homeConfig = {
    imports = [
      self.lib.homeModules.hyprland
      self.lib.homeModules.desktopShell
      self.lib.homeModules.appearance
      self.lib.homeModules.unimatrix

      self.lib.homeModules.apps
      self.lib.homeModules.desktop
      self.lib.homeModules.bash
      self.lib.homeModules.btop
      self.lib.homeModules.gdu
      self.lib.homeModules.dev
      self.lib.homeModules.pi
      self.lib.homeModules.fastfetch
      self.lib.homeModules.fzf
      self.lib.homeModules.directories
      self.lib.homeModules.firefox
      self.lib.homeModules.git
      self.lib.homeModules.kitty
      self.lib.homeModules.lazydocker
      self.lib.homeModules.npm
      self.lib.homeModules.nvim
      self.lib.homeModules.ssh
      self.lib.homeModules.starship

      self.lib.homeModules.screenSharePicker
      self.lib.homeModules.windows
      self.lib.homeModules.vscode
      self.lib.homeModules.yazi
      self.lib.homeModules.zapzap
    ];

    _module.args = { inherit font colors; };

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

  flake.nixosModules.homeManager =
    { ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-backup";
        extraSpecialArgs = specialArgs;
        users.${host.username} = homeConfig;
      };
    };

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
        self.nixosModules.teams
        self.nixosModules.homeManager
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
