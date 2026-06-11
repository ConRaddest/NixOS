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
    stateVersion = "26.05";
  };

  specialArgs = {
    inherit inputs self hostName;
    inherit (host)
      username
      fullName
      homeDirectory
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

  theme = import "${self}/themes/current.nix";
  colors = theme.colors;

  # ============================================================
  # Home
  # ============================================================

  homeConfig = {
    imports = [
      self.lib.homeModules.hypridle
      self.lib.homeModules.hyprland
      self.lib.homeModules.hyprlock
      self.lib.homeModules.hyprpaper
      self.lib.homeModules.theme

      self.lib.homeModules.bash
      self.lib.homeModules.btop
      self.lib.homeModules.fzf
      self.lib.homeModules.directories
      self.lib.homeModules.firefox
      self.lib.homeModules.git
      self.lib.homeModules.kitty
      self.lib.homeModules.npm
      self.lib.homeModules.ssh
      self.lib.homeModules.starship

      self.lib.homeModules.quickshell
      self.lib.homeModules.windows
      self.lib.homeModules.packages
      self.lib.homeModules.yazi
      self.lib.homeModules.icons
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

  flake.systemModules.homeManager =
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

  flake.systemModules.legionConfiguration =
    { stateVersion, ... }:
    {
      imports = [
        self.systemModules.legionHardware

        self.systemModules.core
        self.systemModules.rsa
        self.systemModules.networking
        self.systemModules.nix
        self.systemModules.security

        self.systemModules.fonts
        self.systemModules.hyprland
        self.systemModules.portals

        self.systemModules.bluetooth
        self.systemModules.nvidia

        self.systemModules.audio
        self.systemModules.battery
        self.systemModules.printing

        self.systemModules.docker
        self.systemModules.onepassword
        self.systemModules.packages
        self.systemModules.homeManager
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
      modules = [ self.systemModules.legionConfiguration ];
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
