{ ... }:

{
  flake.systemModules.users =
    { username, fullName, ... }:

    {
      users.users.${username} = {
        isNormalUser = true;
        description = fullName;
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "audio"
          "docker"
          "kvm"
        ];
      };

      security.sudo.wheelNeedsPassword = true;
      security.polkit.enable = true;
    };
}
