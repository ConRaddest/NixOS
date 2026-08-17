{
  inputs,
  self,
  ...
}:

let
  hostName = baseNameOf (toString ./.);
  host = {
    system = "x86_64-linux";
    username = "cdt";
    fullName = "Connor du Toit";
    homeDirectory = "/home/cdt";
    flakeDirectory = "/home/cdt/NixOS";
    stateVersion = "26.05";
    initialHashedPassword = null;
    steam.enable = true;

    trackpad = {
      enable = true;
      name = "msft0001:01-06cb:cd5f-touchpad";
    };

    theme = {
      name = "tokyo-night";
      wallpaper = "backgrounds/0-winding-road.jpg";
    };

    boot = {
      mode = "uefi";
      device = null;
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

    firefox = {
      profilePath = "td4m60gg.default";
      certificatePath = "/home/cdt/.local/share/mkcert/rootCA.pem";
    };

    windows = {
      timeZone = "Africa/Johannesburg";
      memory = "6G";
      cpuCores = 6;
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
      self.lib.homeModules.options
      self.lib.homeModules.nos
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
      self.lib.homeModules.voxtype
      self.lib.homeModules.audio
      self.lib.homeModules.battery
      self.lib.homeModules.bluetooth
      self.lib.homeModules.lazydocker
      self.lib.homeModules.ssh
      self.lib.homeModules.steam
      self.lib.homeModules.windows
    ];

    config = {
      _module.args = { inherit font; };

      nos = {
        inherit (host) theme;
        flakeDirectory = host.flakeDirectory;
        trackpad = host.trackpad.enable;
        trackpadName = host.trackpad.name;
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
        self.nixosModules.nvidia
        self.nixosModules.audio
        self.nixosModules.battery
        self.nixosModules.bluetooth
        self.nixosModules.docker
        self.nixosModules.onepassword
        self.nixosModules.printing
        self.nixosModules.steam
      ];

      nos = {
        inherit (host) boot;
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
