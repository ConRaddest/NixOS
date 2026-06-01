{ ... }:

{
  flake.systemModules.users =
    {
      pkgs,
      username,
      fullName,
      ...
    }:

    {
      users.users.${username} = {
        isNormalUser = true;
        description = fullName;
        shell = pkgs.bash;
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
      security.sudo.extraConfig = "Defaults pwfeedback";
      security.polkit.enable = true;
    };
}
