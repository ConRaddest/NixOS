{ inputs, ... }:

{
  flake.lib.homeModules.pi =
    { pkgs, ... }:

    let
      unstablePkgs = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      home.packages = [ unstablePkgs.pi-coding-agent ];
      home.file = {
        ".pi/agent/SYSTEM.md".source = ./SYSTEM.md;
      };
    };
}
