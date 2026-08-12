{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    # declerative config file management
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # theming engine
    stylix = {
      url = "github:nix-community/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # screen share picker for hyprland with preview window
    hyprland-preview-share-picker = {
      url = "git+https://github.com/WhySoBad/hyprland-preview-share-picker?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # desktop shells
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nice overview for seeing all workspaces on hyprland
    # Pin matching Hyprland 0.55.4 commit from upstream's hyprpm.toml.
    hyprland-scroll-overview = {
      url = "github:yayuuu/hyprland-scroll-overview/cfc23b194ba9378d1606c7aa73060f6ffbe38445";
      flake = false;
    };

  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [
          (inputs.import-tree ./modules/system)
          (inputs.import-tree ./modules/home)
          ((inputs.import-tree.filterNot (lib.hasSuffix "/apps.nix")) ./hosts)
        ];

        options.flake = {
          lib.homeModules = lib.mkOption {
            type = lib.types.lazyAttrsOf lib.types.raw;
            default = { };
            description = "Home Manager modules exported by this flake.";
          };

          homeConfigurations = lib.mkOption {
            type = lib.types.lazyAttrsOf lib.types.raw;
            default = { };
            description = "Standalone Home Manager configurations exported by each host.";
          };
        };

        config = {
          systems = [ "x86_64-linux" ];

          perSystem =
            { pkgs, ... }:
            let
              source = inputs.self;
              nixosChecks = lib.mapAttrs' (
                name: configuration: lib.nameValuePair "nixos-${name}" configuration.config.system.build.toplevel
              ) inputs.self.nixosConfigurations;
              homeChecks = lib.mapAttrs' (
                name: configuration:
                lib.nameValuePair "home-${lib.replaceStrings [ "@" ] [ "-at-" ] name}" configuration.activationPackage
              ) inputs.self.homeConfigurations;
            in
            {
              formatter = pkgs.nixfmt;

              checks = {
                formatting =
                  pkgs.runCommand "check-nix-formatting"
                    {
                      nativeBuildInputs = [
                        pkgs.findutils
                        pkgs.nixfmt
                      ];
                    }
                    ''
                      cd ${source}
                      find . -name '*.nix' -print0 | xargs -0 -r nixfmt --check
                      touch "$out"
                    '';

                dead-code =
                  pkgs.runCommand "check-dead-code"
                    {
                      nativeBuildInputs = [ pkgs.deadnix ];
                    }
                    ''
                      deadnix --fail ${source}
                      touch "$out"
                    '';

                static-analysis =
                  pkgs.runCommand "check-static-analysis"
                    {
                      nativeBuildInputs = [ pkgs.statix ];
                    }
                    ''
                      statix check --config ${source}/statix.toml ${source}
                      touch "$out"
                    '';

                shell-scripts =
                  pkgs.runCommand "check-shell-scripts"
                    {
                      nativeBuildInputs = [
                        pkgs.findutils
                        pkgs.shellcheck
                      ];
                    }
                    ''
                      cd ${source}
                      find . -name '*.sh' -print0 | xargs -0 -r shellcheck
                      touch "$out"
                    '';

              }
              // nixosChecks
              // homeChecks;
            };
        };
      }
    );
}
