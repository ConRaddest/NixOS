{ ... }:

{
  flake.nixosModules.security =
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
          "video"
          "audio"
          "docker"
          "kvm"
        ];
      };

      security.sudo.wheelNeedsPassword = true;
      security.sudo.extraConfig = "Defaults pwfeedback";
      security.sudo.extraRules = [
        {
          users = [ username ];
          commands = [
            {
              command = "/run/current-system/sw/bin/nixos-rebuild";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
      security.polkit.enable = true;
    };
}
