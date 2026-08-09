{
  self,
  inputs,
  lib,
  ...
}:

let
  # Copy this directory to hosts/<host-name>. hostName then derives from
  # directory name, keeping NixOS and Home Manager outputs unique.
  hostName = builtins.baseNameOf (toString ./.);

  host = {
    system = "x86_64-linux";
    username = "cdt";
    fullName = "cdt";
    homeDirectory = "/home/cdt";
    flakeDirectory = "/home/cdt/NixOS";
    stateVersion = "26.05";
    initialHashedPassword = "$y$j9T$0GcQYCQFpGg11RuTdnVdl0$jT7aBB4Q8giBYjEkLn.joN0tLcpsLs0foJN7ue3Saw7";
    gaming = true;

    boot = {
      mode = "uefi";
      device = null;
    };

    hardware = {
      deepSleep = false;
      thermald = true;
      nvidiaOpen = false;
      nvidiaPrime = null;
    };

    git = {
      name = "cdt";
      email = "cdt@legion";
    };

    region = {
      timeZone = "Africa/Johannesburg";
      locale = "en_ZA.UTF-8";
      keyboardLayout = "za";
    };

    localHosts = [ ];
    monitors = [ ];

    gduMaxCores = 12;
    firefoxProfilePath = "td4m60gg.default";
    firefoxCertificatePath = null;

    windows = {
      timeZone = "Africa/Johannesburg";
      memory = "4G";
      cpuCores = 12;
      diskSize = "64G";
    };
  };

  font = {
    system = "Adwaita Sans";
    size = 11;
    mono = "JetBrainsMono Nerd Font";
    monoSize = 10;
  };

  specialArgs = {
    inherit
      inputs
      self
      host
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

  homeConfig = {
    imports = [
      # Shell and core user environment
      self.lib.homeModules.shell
      self.lib.homeModules.appearance
      self.lib.homeModules.apps
      self.lib.homeModules.btop
      self.lib.homeModules.directories
      self.lib.homeModules.dev
      self.lib.homeModules.fastfetch
      self.lib.homeModules.fzf
      self.lib.homeModules.gdu
      self.lib.homeModules.git
      self.lib.homeModules.npm
      self.lib.homeModules.nvim
      self.lib.homeModules.pi
      self.lib.homeModules.starship
      self.lib.homeModules.yazi

      # Desktop environment
      self.lib.homeModules.desktop
      self.lib.homeModules.dms
      self.lib.homeModules.firefox
      self.lib.homeModules.hyprland
      self.lib.homeModules.kitty
      self.lib.homeModules.screenSharePicker
      self.lib.homeModules.zapzap
    ];

    options.nos = {
      flakeDirectory = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Mutable checkout path used by repository helper commands.";
      };
      trackpad = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether host has a trackpad.";
      };
      trackpadName = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Hyprland input device name for host trackpad.";
      };
    };

    config = {
      _module.args = { inherit font; };

      nos = {
        flakeDirectory = host.flakeDirectory;
        trackpad = false;
        trackpadName = null;
      };

      home.username = host.username;
      home.homeDirectory = host.homeDirectory;
      home.stateVersion = host.stateVersion;

      programs.home-manager.enable = true;
    };
  };
in
{
  flake.nixosModules."${hostName}Configuration" =
    { stateVersion, ... }:
    {
      imports = [
        self.nixosModules."${hostName}Hardware"
        inputs.home-manager.nixosModules.home-manager

        self.nixosModules.options
        self.nixosModules.boot
        self.nixosModules.core
        self.nixosModules.rsa
        self.nixosModules.networking
        self.nixosModules.nix
        self.nixosModules.security
        self.nixosModules.vscode

        self.nixosModules.hyprland
        self.nixosModules.portals

        self.nixosModules.bluetooth
        self.nixosModules.audio
        self.nixosModules.battery
        self.nixosModules.printing
        self.nixosModules.docker
        self.nixosModules.gaming
        self.nixosModules.onepassword
      ];

      nos = {
        boot = host.boot;
        hardware = host.hardware;
      };

      networking.hostName = hostName;
      system.stateVersion = stateVersion;

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = specialArgs;
        users.${host.username} = homeConfig;
      };
    };

  flake.nixosConfigurations = {
    "${hostName}" = inputs.nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      system = host.system;
      modules = [ self.nixosModules."${hostName}Configuration" ];
    };
  };

  flake.homeConfigurations = {
    "${host.username}@${hostName}" = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = specialArgs;
      modules = [ homeConfig ];
    };
  };
}
