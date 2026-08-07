{ self, inputs, ... }:

let
  fontDefaults = {
    system = "Adwaita Sans";
    size = 11;
    mono = "JetBrainsMono Nerd Font";
    monoSize = 10;
  };

  homeModule =
    {
      config,
      lib,
      ...
    }:
    {
      options.nos = {
        isNixOS = lib.mkOption {
          type = lib.types.bool;
          default = false;
          internal = true;
          description = "Whether Home Manager is evaluated inside NixOS.";
        };
        flakeDirectory = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "Mutable checkout path used by repository helper commands.";
        };
      };

      imports = [
        self.lib.homeModules.shell
        self.lib.homeModules.btop
        self.lib.homeModules.gdu
        self.lib.homeModules.dev
        self.lib.homeModules.pi
        self.lib.homeModules.fastfetch
        self.lib.homeModules.fzf
        self.lib.homeModules.directories
        self.lib.homeModules.git
        self.lib.homeModules.lazydocker
        self.lib.homeModules.npm
        self.lib.homeModules.nvim
        self.lib.homeModules.ssh
        self.lib.homeModules.starship
        self.lib.homeModules.yazi

        self.lib.homeModules.hyprland
        self.lib.homeModules.dms
        self.lib.homeModules.appearance
        self.lib.homeModules.apps
        self.lib.homeModules.firefox
        self.lib.homeModules.kitty
        self.lib.homeModules.screenSharePicker
        self.lib.homeModules.zapzap
        self.lib.homeModules.desktop
        self.lib.homeModules.windows
      ];

      config = {
        # Defaults let other flakes import homeManagerModules.default directly.
        _module.args = {
          inherit inputs self;
          font = lib.mkDefault fontDefaults;
        };

        # Target profile: x86_64 Linux. No NixOS-only module options used here.
        targets.genericLinux.enable = !config.nos.isNixOS;
      };
    };
in
{
  flake.lib.homeModules.home = homeModule;

  # Reusable by NixOS, non-NixOS Linux, and flakes importing this one.
  flake.homeManagerModules.default = homeModule;

  flake.lib.mkHomeConfiguration =
    {
      system,
      username,
      homeDirectory,
      stateVersion,
      flakeDirectory ? null,
      font ? fontDefaults,
      extraModules ? [ ],
      extraSpecialArgs ? { },
    }:
    let
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit
          inputs
          self
          username
          homeDirectory
          stateVersion
          flakeDirectory
          font
          ;
      }
      // extraSpecialArgs;
      modules = [
        homeModule
        {
          home = {
            inherit username homeDirectory stateVersion;
          };
          nos.flakeDirectory = flakeDirectory;
          programs.home-manager.enable = true;
        }
      ]
      ++ extraModules;
    };
}
