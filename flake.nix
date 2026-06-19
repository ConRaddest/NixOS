{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    hyprland-preview-share-picker = {
      url = "git+https://github.com/WhySoBad/hyprland-preview-share-picker?submodules=1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [
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
