{ ... }:

{
  flake.lib.homeModules.pi =
    { pkgs, ... }:

    let
      pi = pkgs.buildNpmPackage {
        pname = "pi-coding-agent";
        version = "0.84.1";
        src = ./.;
        npmDepsHash = "sha256-Okh/EoiUDwFI8cNdwF/LHVXAA5wWylvprakQIVqBGNo=";
        npmDepsFetcherVersion = 2;
        dontNpmBuild = true;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        installPhase = ''
          runHook preInstall
          mkdir -p "$out/lib" "$out/bin"
          cp -R node_modules "$out/lib/node_modules"
          makeWrapper ${pkgs.nodejs}/bin/node "$out/bin/pi" \
            --add-flags "$out/lib/node_modules/@earendil-works/pi-coding-agent/dist/cli.js"
          runHook postInstall
        '';
      };
    in
    {
      home.packages = [ pi ];
      home.file = {
        ".pi/agent/SYSTEM.md".source = ./SYSTEM.md;
      };
    };
}
