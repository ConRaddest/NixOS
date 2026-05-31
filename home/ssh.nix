{ ... }:

{
  flake.lib.homeModules.ssh =
    { self, ... }:

    {
      home.file.".ssh/config".source = "${self}/config/ssh/config";
    };
}
