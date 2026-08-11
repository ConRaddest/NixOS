{
  self,
  inputs,
  lib,
  ...
}:

let
  # ============================================================
  # Host
  # ============================================================

  hostName = builtins.baseNameOf (toString ./.);
  host = {
    system = "x86_64-linux";
    username = "cdt";
    fullName = "Connor du Toit";
    homeDirectory = "/home/cdt";
    flakeDirectory = "/home/cdt/NixOS";
    stateVersion = "26.05";
    initialHashedPassword = null;
    gaming = true;
    desktopShell = "noctalia"; # "dms" || "noctalia"


    boot = {
      mode = "uefi";
      device = null;
    };

    hardware = {
      deepSleep = true;
      thermald = true;
      nvidiaOpen = false;
      nvidiaPrime = null;
    };

    git = {
      name = "Connor du Toit";
      email = "connordutoit@gmail.com";
    };

    region = {
      timeZone = "Africa/Johannesburg";
      locale = "en_ZA.UTF-8";
      keyboardLayout = "za";
    };

    localHosts = [
      "management-local.pmis.servicesseta.org.za"
      "partner-local.pmis.servicesseta.org.za"
      "learner-local.pmis.servicesseta.org.za"
    ];

    mounts = [
      {
        mountPoint = "/home/cdt/SSD";
        device = "/dev/disk/by-uuid/703e86da-1c1b-4ae8-afd6-99312da4a1be";
        fsType = "ext4";
        options = [ "nofail" ];
      }
    ];

    monitors = [
      {
        output = "eDP-1";
        mode = "1920x1080@60";
        position = "0x0";
        scale = 1;
        workspaces = [
          1
          2
          3
        ];
      }
      {
        output = "HDMI-A-1";
        mode = "3440x1440@174.96";
        position = "1920x0";
        scale = 1;
        workspaces = [
          4
          5
          6
          7
          8
          9
        ];
      }
    ];

    gduMaxCores = 12;
    firefoxProfilePath = "td4m60gg.default";
    firefoxCertificatePath = "/home/cdt/.local/share/mkcert/rootCA.pem";

    windows = {
      timeZone = "Africa/Johannesburg";
      memory = "6G";
      cpuCores = 6;
      diskSize = "64G";
    };
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
    imports = [
      # Shell and core user environment
      self.lib.homeModules.shell
      self.lib.homeModules.appearance
      self.lib.homeModules.theme
      self.lib.homeModules.apps
      self.lib.homeModules.audio
      self.lib.homeModules.battery
      self.lib.homeModules.bluetooth
      self.lib.homeModules.btop
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
      self.lib.homeModules.${host.desktopShell}
      self.lib.homeModules.firefox
      self.lib.homeModules.hyprland
      self.lib.homeModules.kitty
      self.lib.homeModules.screenSharePicker
      self.lib.homeModules.windows
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
        trackpad = true;
        trackpadName = "msft0001:01-06cb:cd5f-touchpad";
      };

      home.username = host.username;
      home.homeDirectory = host.homeDirectory;
      home.stateVersion = host.stateVersion;

      nixpkgs.config.allowUnfree = true;

      programs.home-manager.enable = true;
    };
  };
in
{
  # ============================================================
  # System modules
  # ============================================================

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
        self.nixosModules.nvidia

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
        useGlobalPkgs = false;
        useUserPackages = true;
        extraSpecialArgs = specialArgs;
        users.${host.username} = homeConfig;
      };
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

  };

  flake.homeConfigurations = {
    "${host.username}@${hostName}" = inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = specialArgs;
      modules = [ homeConfig ];
    };
  };
}
