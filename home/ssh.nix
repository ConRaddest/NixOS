{ ... }:

{
  flake.lib.homeModules.ssh =
    { ... }:

    {
      programs.ssh = {
        enable = true;
        matchBlocks."*".extraOptions.IdentityAgent = "~/.1password/agent.sock";
      };
    };
}
