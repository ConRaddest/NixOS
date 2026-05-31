{ self, inputs, ... }:

# Template — copy this folder, rename "example" to your hostname everywhere,
# fill in the blanks, and uncomment what you need.
# Nothing in this file is exported until you add real flake.* entries below.

let
  # ============================================================
  # Host
  # ============================================================

  hostName = "example"; # must match the folder name and nixosConfigurations key below

  host = {
    system = "x86_64-linux"; # or "aarch64-linux" for ARM
    username = ""; # your login username
    fullName = ""; # used for git config, display names, etc.
    homeDirectory = "/home/"; # /home/<username>
    stateVersion = "26.05"; # set to the NixOS version you installed with — do not change after install
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

  # Instantiate pkgs for standalone home-manager builds (see homeConfigurations below).
  pkgs = import inputs.nixpkgs {
    system = host.system;
    config.allowUnfree = true;
  };

  # ============================================================
  # Theme
  # ============================================================

  # These are passed as module args to every home module via _module.args.
  # Access them in any home module with: { font, colors, ... }:

  font = {
    name = ""; # sans-serif UI font (e.g. "Cantarell")
    size = 11;
    mono = ""; # monospace font for terminals/editors (e.g. "JetBrainsMono Nerd Font")
    monoSize = 10;
  };

  colors = {
    # Backgrounds
    bg = "";
    bgDark = "";
    bgAlt = "";

    # Foregrounds
    fg = "";
    fgDark = "";
    fgDim = "";

    # UI surfaces
    hover = "";
    comment = "";
    selection = "";
    surfaceLight = "";

    # Palette
    black = "";
    red = "";
    orange = "";
    yellow = "";
    green = "";
    teal = "";
    cyan = "";
    blue = "";
    magenta = "";
    purple = "";
  };

  # ============================================================
  # Home
  # ============================================================

  homeConfig = {
    imports = [
      # Desktop — window manager, lock screen, idle daemon, wallpaper
      # self.lib.homeModules.hypridle
      # self.lib.homeModules.hyprland
      # self.lib.homeModules.hyprlock
      # self.lib.homeModules.hyprpaper
      # self.lib.homeModules.theme

      # Programs — per-app config
      # self.lib.homeModules.btop
      # self.lib.homeModules.firefox
      # self.lib.homeModules.kitty
      # self.lib.homeModules.ssh
      # self.lib.homeModules.starship
      # self.lib.homeModules.vscode

      # Shell & misc
      # self.lib.homeModules.quickshell
      # self.lib.homeModules.windows
      # self.lib.homeModules.packages
    ];

    # Makes font and colors available in all home modules.
    _module.args = { inherit font colors; };

    home.username = host.username;
    home.homeDirectory = host.homeDirectory;
    home.stateVersion = host.stateVersion;

    programs.home-manager.enable = true;
  };
in

# ============================================================
# Exports
# ============================================================

# Uncomment and fill in the sections below when setting up a real host.
# Replace every occurrence of "example" with your hostname.

{
  # flake.systemModules.exampleHomeManager =
  #   { ... }:
  #   {
  #     imports = [ inputs.home-manager.nixosModules.home-manager ];
  #     home-manager = {
  #       useGlobalPkgs = true;
  #       useUserPackages = true;
  #       backupFileExtension = "hm-backup";
  #       extraSpecialArgs = specialArgs;
  #       users.${host.username} = homeConfig;
  #     };
  #   };

  # flake.systemModules.exampleConfiguration =
  #   { stateVersion, ... }:
  #   {
  #     imports = [
  #       # Always include your hardware file.
  #       self.systemModules.exampleHardware
  #
  #       # Core — required on every host
  #       self.systemModules.boot
  #       self.systemModules.locale
  #       self.systemModules.networking
  #       self.systemModules.nix
  #       self.systemModules.users
  #
  #       # Desktop — remove if running headless
  #       # self.systemModules.fonts
  #       # self.systemModules.greetd
  #       # self.systemModules.hyprland
  #       # self.systemModules.portals
  #
  #       # Hardware — include only what this machine has
  #       # self.systemModules.bluetooth
  #       # self.systemModules.nvidia   # only if NVIDIA GPU
  #
  #       # Services
  #       # self.systemModules.audio
  #       # self.systemModules.power    # recommended for laptops
  #       # self.systemModules.printing
  #
  #       # Virtualisation
  #       # self.systemModules.docker
  #
  #       # Always last — wires home-manager in after everything else
  #       self.systemModules.packages
  #       self.systemModules.exampleHomeManager
  #     ];
  #     networking.hostName = hostName;
  #     system.stateVersion = stateVersion;
  #   };

  # flake.nixosConfigurations = {
  #   ${hostName} = inputs.nixpkgs.lib.nixosSystem {
  #     inherit specialArgs;
  #     system = host.system;
  #     modules = [ self.systemModules.exampleConfiguration ];
  #   };
  #   # "nixos" is a convenience alias — only one host can claim it.
  #   # nixos = self.nixosConfigurations.${hostName};
  # };

  # flake.homeConfigurations = {
  #   ${host.username} = inputs.home-manager.lib.homeManagerConfiguration {
  #     inherit pkgs;
  #     extraSpecialArgs = specialArgs;
  #     modules = [ homeConfig ];
  #   };
  #   "${host.username}@${hostName}" = self.homeConfigurations.${host.username};
  # };
}
