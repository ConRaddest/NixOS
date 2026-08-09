{ ... }:

{
  flake.nixosModules.security =
    {
      config,
      host,
      lib,
      pkgs,
      username,
      fullName,
      ...
    }:

    {
      programs.fish.enable = true;

      users.users.${username} = {
        isNormalUser = true;
        description = fullName;
        shell = pkgs.fish;
        extraGroups = [
          "wheel"
          "networkmanager"
          "video"
          "audio"
          "kvm"
        ]
        ++ lib.optional config.virtualisation.docker.enable "docker";
      }
      // lib.optionalAttrs (host.initialHashedPassword != null) {
        initialHashedPassword = host.initialHashedPassword;
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
