{ ... }:

{
  flake.lib.homeModules.apps =
    {
      config,
      hostName,
      lib,
      pkgs,
      self,
      ...
    }:

    let
      appsFile = "${self}/hosts/${hostName}/apps.nix";
      packageFor =
        name:
        lib.attrByPath (lib.splitString "." name) (throw "Unknown package in ${appsFile}: ${name}") pkgs;
      requestedPackages = map packageFor config.nos.apps;
      availablePackages = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) requestedPackages;
    in
    {
      imports = lib.optional (builtins.pathExists appsFile) appsFile;

      options.nos.apps = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Nixpkgs package attributes installed for this host.";
      };

      config = {
        home.packages = availablePackages;

        # Hide upstream entry that has NoDisplay=true but still surfaces in launchers.
        xdg.desktopEntries.uuctl = {
          name = "uuctl";
          exec = "uuctl";
          noDisplay = true;
          type = "Application";
        };

        warnings =
          lib.optional (builtins.length requestedPackages != builtins.length availablePackages)
            "Some packages in ${appsFile} are unavailable on ${pkgs.stdenv.hostPlatform.system} and were skipped.";
      };
    };
}
