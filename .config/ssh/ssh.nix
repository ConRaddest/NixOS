{ config, configDir, ... }:

{
  home.file.".ssh/config" = {
    source = config.lib.file.mkOutOfStoreSymlink "${configDir}/.config/ssh/config";
  };
}
