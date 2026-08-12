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

      security = {
        polkit = {
          enable = true;
        };
        sudo = {
          extraConfig = "Defaults pwfeedback";
          wheelNeedsPassword = true;
        };
      };
    };
}
