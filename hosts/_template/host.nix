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
      self.lib.homeModules.audio
      self.lib.homeModules.battery
      self.lib.homeModules.bluetooth
      self.lib.homeModules.directories
      self.lib.homeModules.dev
      self.lib.homeModules.fastfetch
      self.lib.homeModules.fzf
      self.lib.homeModules.gdu
      self.lib.homeModules.git
      self.lib.homeModules.lazydocker
      self.lib.homeModules.npm
      self.lib.homeModules.nvim
      self.lib.homeModules.pi
      self.lib.homeModules.ssh
      self.lib.homeModules.starship
      self.lib.homeModules.yazi

      # Desktop environment
      self.lib.homeModules.desktop
      self.lib.homeModules.dms
      self.lib.homeModules.firefox
      self.lib.homeModules.hyprland
      self.lib.homeModules.kitty
      self.lib.homeModules.screenSharePicker
      self.lib.homeModules.windows
      self.lib.homeModules.zapzap
    ];

    options.nos.flakeDirectory = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Mutable checkout path used by repository helper commands.";
    };

    config = {
      _module.args = { inherit font; };

      nos.flakeDirectory = host.flakeDirectory;

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
