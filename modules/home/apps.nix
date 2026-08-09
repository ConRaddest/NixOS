{ ... }:

{
  flake.lib.homeModules.apps =
    {
      hostName,
      lib,
      pkgs,
      self,
      ...
    }:

    let
      appsFile = "${self}/hosts/${hostName}/apps.txt";
      appNames =
        if builtins.pathExists appsFile then
          lib.filter (name: name != "" && !(lib.hasPrefix "#" name)) (
            lib.splitString "\n" (builtins.readFile appsFile)
          )
        else
          [ ];
      packageFor =
        name:
        lib.attrByPath (lib.splitString "." name) (throw "Unknown package in ${appsFile}: ${name}") pkgs;
      requestedPackages = map packageFor appNames;
      availablePackages = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) requestedPackages;
    in
    {
      home.packages = availablePackages;

      warnings = lib.optional (builtins.length requestedPackages != builtins.length availablePackages) (
        "Some packages in ${appsFile} are unavailable on ${pkgs.stdenv.hostPlatform.system} and were skipped."
      );
    };
}
