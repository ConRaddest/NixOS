{ ... }:

{
  flake.lib.homeModules.ssh =
    { self, ... }:

    {
      home.file.".ssh/config".source =
        "${self}/assets/ssh/config";
    }
;
}
