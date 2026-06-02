{
  # -------- TODO LIST -----------
  # 1. Logout breaks alot of things, need a way to gracefully exit with splash screen
  # 2. Need get suspend working so i have a way of shutting down without losing any app progress
  # 3. Need to fix volume OSD to not go infinitely louder (although pretty cool) - maybe make it match what the volume level actually is?
  # 4. Need to make volume OSD apply to all outputs instead of just the default output
  # 5. Need to pull pi from github (source) rather than nix branch to always get latest versions

  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    wrapper-modules.url = "github:BirdeeHub/nix-wrapper-modules";
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

        options.flake.systemModules = lib.mkOption {
          type = lib.types.lazyAttrsOf lib.types.raw;
          default = { };
          description = "NixOS system modules exported by this flake.";
        };

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
