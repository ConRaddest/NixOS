{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    firefox-nixpkgs.url = "github:nixos/nixpkgs/0ad6f47ea4fe188f4bc8f0380f93ae8523337c6c";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland-preview-share-picker = {
      url = "git+https://github.com/WhySoBad/hyprland-preview-share-picker?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pin matching Hyprland 0.55.4 commit from upstream's hyprpm.toml.
    hyprland-scroll-overview = {
      url = "github:yayuuu/hyprland-scroll-overview/cfc23b194ba9378d1606c7aa73060f6ffbe38445";
      flake = false;
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [
          ./home.nix
          (inputs.import-tree ./system)
          (inputs.import-tree ./home)
          (inputs.import-tree ./hosts)
        ];

        options.flake.lib.homeModules = lib.mkOption {
          type = lib.types.lazyAttrsOf lib.types.raw;
          default = { };
          description = "Home Manager modules exported by this flake.";
        };

        config = {
          systems = [ "x86_64-linux" ];

          perSystem =
            { pkgs, ... }:
            {
              formatter = pkgs.nixfmt;
            };
        };
      }
    );
}
