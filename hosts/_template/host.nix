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
    username = "CHANGE_ME";
    fullName = "CHANGE_ME";
    homeDirectory = "/home/CHANGE_ME";
    flakeDirectory = "/home/CHANGE_ME/NixOS";
    stateVersion = "26.05";
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
      # AUDIO_HOME_MODULE
      # BATTERY_HOME_MODULE
      # BLUETOOTH_HOME_MODULE
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
      self.lib.homeModules.desktop
      self.lib.homeModules.dms
      self.lib.homeModules.firefox
      self.lib.homeModules.hyprland
      self.lib.homeModules.kitty
      self.lib.homeModules.screenSharePicker
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

        self.nixosModules.core
        self.nixosModules.rsa
        self.nixosModules.networking
        self.nixosModules.nix
        self.nixosModules.security
        self.nixosModules.vscode

        self.nixosModules.hyprland
        self.nixosModules.portals

        # GPU_MODULE
        # BLUETOOTH_SYSTEM_MODULE
        # AUDIO_SYSTEM_MODULE
        # BATTERY_SYSTEM_MODULE
        # PRINTING_SYSTEM_MODULE
        # DOCKER_SYSTEM_MODULE
        # ONEPASSWORD_SYSTEM_MODULE
      ];

      networking.hostName = hostName;
      system.stateVersion = stateVersion;
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
