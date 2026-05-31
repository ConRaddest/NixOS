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
    name = "Cantarell";
    size = 11;
    mono = "JetBrainsMono Nerd Font";
    monoSize = 10;
  };

  colors = {
    bg = "#1a1b26";
    bgDark = "#16161e";
    bgAlt = "#292e42";

    fg = "#c0caf5";
    fgDark = "#a9b1d6";
    fgDim = "#565f89";

    hover = "#222637";
    comment = "#565f89";
    selection = "#2b2f3a";
    surfaceLight = "#2a2f43";

    black = "#414868";
    red = "#f7768e";
    orange = "#ff9e64";
    yellow = "#e0af68";
    green = "#9ece6a";
    teal = "#73daca";
    cyan = "#7dcfff";
    blue = "#7aa2f7";
    magenta = "#bb9af7";
    purple = "#9d7cd8";
  };

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

      self.lib.homeModules.btop
      self.lib.homeModules.firefox
      self.lib.homeModules.kitty
      self.lib.homeModules.ssh
      self.lib.homeModules.starship
      self.lib.homeModules.vscode

      self.lib.homeModules.quickshell
      self.lib.homeModules.windows
      self.lib.homeModules.packages
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
  # System
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

        self.systemModules.boot
        self.systemModules.locale
        self.systemModules.networking
        self.systemModules.nix
        self.systemModules.users

        self.systemModules.fonts
        self.systemModules.greetd
        self.systemModules.hyprland
        self.systemModules.portals

        self.systemModules.bluetooth
        self.systemModules.nvidia

        self.systemModules.audio
        self.systemModules.power
        self.systemModules.printing

        self.systemModules.docker
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
