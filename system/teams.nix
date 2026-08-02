{ ... }:

{
  flake.nixosModules.teams =
    { pkgs, ... }:

    {
      # Fix teams-for-linux freezing on sleep/resume.
      systemd.services.teams-resume-fix = {
        description = "Kill stuck Teams for Linux processes on resume";
        after = [
          "suspend.target"
          "hybrid-sleep.target"
          "hibernate.target"
        ];
        wantedBy = [
          "suspend.target"
          "hybrid-sleep.target"
          "hibernate.target"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.procps}/bin/pkill -f teams-for-linux || true";
        };
      };
    };
}
