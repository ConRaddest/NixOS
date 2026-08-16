{
  inputs,
  lib,
  self,
  ...
}:

let
  # Copy this directory to hosts/<host-name>. Output names derive from directory name.
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

    features = {
      audio = false;
      battery = false;
      bluetooth = false;
      docker = false;
      onepassword = false;
      printing = false;
      steam = true;
      windows = false;
      graphics = {
        primary = "none";
        integrated = null;
      };
    };

    development.mutableConfig = false;
    trackpad = {
      enable = false;
      name = null;
    };

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

  optionalHomeModules =
    with self.lib.homeModules;
    lib.optionals host.features.audio [ audio ]
    ++ lib.optionals host.features.battery [ battery ]
    ++ lib.optionals host.features.bluetooth [ bluetooth ]
    ++ lib.optionals host.features.docker [ lazydocker ]
    ++ lib.optionals host.features.onepassword [ ssh ]
    ++ lib.optionals host.features.steam [ steam ]
    ++ lib.optionals host.features.windows [ windows ];

  graphicsModules =
    if host.features.graphics.primary == "none" then
      [ ]
    else
      [ self.nixosModules.${host.features.graphics.primary} ]
      ++ lib.optionals (
        host.features.graphics.primary == "nvidia" && host.features.graphics.integrated != null
      ) [ self.nixosModules.${host.features.graphics.integrated} ];

  optionalSystemModules =
    graphicsModules
    ++ lib.optionals host.features.audio [ self.nixosModules.audio ]
    ++ lib.optionals host.features.battery [ self.nixosModules.battery ]
    ++ lib.optionals host.features.bluetooth [ self.nixosModules.bluetooth ]
    ++ lib.optionals host.features.docker [ self.nixosModules.docker ]
    ++ lib.optionals host.features.onepassword [ self.nixosModules.onepassword ]
    ++ lib.optionals host.features.printing [ self.nixosModules.printing ]
    ++ lib.optionals host.features.steam [ self.nixosModules.steam ];

  homeConfig = {
    imports = [
      self.lib.homeModules.options
      self.lib.homeModules.bin
      self.lib.homeModules.terminal
      self.lib.homeModules.appearance
      self.lib.homeModules.theme
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
      self.lib.homeModules.dms
      self.lib.homeModules.firefox
      self.lib.homeModules.hyprland
      self.lib.homeModules.kitty
      self.lib.homeModules.slack
      self.lib.homeModules.zapzap
      self.lib.homeModules.screen-share-picker
      self.lib.homeModules.screensaver
      self.lib.homeModules.voxtype
    ]
    ++ optionalHomeModules;

    config = {
      _module.args = { inherit font; };

      nos = {
        inherit (host) theme;
        flakeDirectory = host.flakeDirectory;
        trackpad = host.trackpad.enable;
        trackpadName = host.trackpad.name;
        development.mutableConfig = host.development.mutableConfig;
      };

      home = {
        inherit (host) homeDirectory stateVersion username;
      };

      nixpkgs.config.allowUnfree = true;
      programs.home-manager.enable = true;
    };
  };

  systemConfig =
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
      ]
      ++ optionalSystemModules;

      nos = {
        inherit (host) boot hardware;
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
in
{
  flake = {
    nixosModules."${hostName}Configuration" = systemConfig;

    nixosConfigurations.${hostName} = inputs.nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      system = host.system;
      modules = [ systemConfig ];
    };

    homeConfigurations."${host.username}@${hostName}" =
      inputs.home-manager.lib.homeManagerConfiguration
        {
          inherit pkgs;
          extraSpecialArgs = specialArgs;
          modules = [ homeConfig ];
        };
  };
}
