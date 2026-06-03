{ ... }:

{
  flake.lib.homeModules.ssh =
    { ... }:

    {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;
        settings."*".IdentityAgent = "~/.1password/agent.sock";
      };
    };
}
