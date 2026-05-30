{ config, ... }:

{
  home.file.".ssh/config" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/OS/.config/ssh/config";
  };
}
