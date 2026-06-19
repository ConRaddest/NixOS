{ ... }:

{
  flake.lib.homeModules.packages =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        # cli utilities
        eza # better ls
        jq # json cli proccessor
        tldr # command summaries
        tree # folder
        unzip # unzip files
      ];
    };
}
