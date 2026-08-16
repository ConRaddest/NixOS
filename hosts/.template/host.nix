{
  self,
  inputs,
  lib,
  ...
}:

let
  # Copy this directory to hosts/<host-name>. hostName then derives from
  # directory name, keeping NixOS and Home Manager outputs unique.
  hostName = baseNameOf (toString ./.);

  host = {
    system = "x86_64-linux";
    username = "CHANGE_ME";
    fullName = "CHANGE_ME";
    homeDirectory = "/home/CHANGE_ME";
    flakeDirectory = "/home/CHANGE_ME/NixOS";
    stateVersion = "26.05";
    initialHashedPassword = null;
    steam.enable = true;
    theme = {
      name = "tokyo-night";
      wallpaper = "backgrounds/0-winding-road.png";
    };

    boot = {
      mode = "uefi";
      device = null;
    };

    hardware = {
      deepSleep = false;
      thermald = false;
      nvidiaOpen = false;
      nvidiaPrime = null;
    };

    git = {
      name = "CHANGE_ME";
      email = "CHANGE_ME";
    };

    region = {
      timeZone = "UTC";
      locale = "en_US.UTF-8";
      keyboardLayout = "us";
    };

    localHosts = [ ];
    mounts = [ ];
    monitors = [ ];

    gduMaxCores = 4;
    firefoxProfilePath = "default";
    firefoxCertificatePath = null;

    windows = {
      timeZone = "UTC";
      memory = "4G";
      cpuCores = 4;
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
      # Terminal and core user environment
      self.lib.homeModules.bin
      self.lib.homeModules.terminal
      self.lib.homeModules.appearance
      self.lib.homeModules.theme
      self.lib.homeModules.apps
      # AUDIO_HOME_MODULE
      # BATTERY_HOME_MODULE
      # BLUETOOTH_HOME_MODULE
      self.lib.homeModules.btop
      self.lib.homeModules.directories
      self.lib.homeModules.dev
      self.lib.homeModules.fastfetch
      self.lib.homeModules.fzf
      self.lib.homeModules.gdu
      self.lib.homeModules.git
      # DOCKER_HOME_MODULE
      self.lib.homeModules.npm
      self.lib.homeModules.nvim
      self.lib.homeModules.pi
      # ONEPASSWORD_HOME_MODULE
      self.lib.homeModules.starship
      self.lib.homeModules.yazi

      # Desktop environment
      self.lib.homeModules.dms
      self.lib.homeModules.firefox
      self.lib.homeModules.hyprland
      self.lib.homeModules.kitty
      self.lib.homeModules.slack
      self.lib.homeModules.steam
      self.lib.homeModules.teamsForLinux
      # WINDOWS_HOME_MODULE
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
        inherit (host) theme;
        flakeDirectory = host.flakeDirectory;
        trackpad = false;
        trackpadName = null;
      };

      home = {
        homeDirectory = host.homeDirectory;
        stateVersion = host.stateVersion;
        username = host.username;
      };

      nixpkgs.config.allowUnfree = true;

      programs.home-manager.enable = true;
    };
  };
in
{
  flake = {
    nixosModules."${hostName}Configuration" =
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

          # GPU_MODULE
          # INTEGRATED_GPU_MODULE
          # BLUETOOTH_SYSTEM_MODULE
          # AUDIO_SYSTEM_MODULE
          # BATTERY_SYSTEM_MODULE
          # PRINTING_SYSTEM_MODULE
          # DOCKER_SYSTEM_MODULE
          # STEAM_SYSTEM_MODULE
          # ONEPASSWORD_SYSTEM_MODULE
        ];

        nos = {
          boot = host.boot;
          hardware = host.hardware;
        };

        networking.hostName = hostName;
        system.stateVersion = stateVersion;

        home-manager = {
          useGlobalPkgs = false;
          useUserPackages = true;
          extraSpecialArgs = specialArgs;
          users.${host.username} = homeConfig;
        };
      };

    nixosConfigurations = {
      "${hostName}" = inputs.nixpkgs.lib.nixosSystem {
        inherit specialArgs;
        system = host.system;
        modules = [ self.nixosModules."${hostName}Configuration" ];
      };
    };

    homeConfigurations = {
      "${host.username}@${hostName}" = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = specialArgs;
        modules = [ homeConfig ];
      };
    };
  };
}
