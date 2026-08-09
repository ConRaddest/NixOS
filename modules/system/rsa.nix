{ ... }:

{
  flake.nixosModules.rsa =
    { host, ... }:

    {
      time.timeZone = host.region.timeZone;
      i18n.defaultLocale = host.region.locale;
      services.xserver.xkb.layout = host.region.keyboardLayout;
    };
}
