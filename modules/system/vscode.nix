{ ... }:

{
  flake.nixosModules.vscode =
    { pkgs, ... }:

    {
      # VS Code extensions ship vendor-provided dynamically linked binaries.
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          icu
          krb5
          libunwind
          openssl
          stdenv.cc.cc
          util-linux
          zlib
        ];
      };
    };
}
