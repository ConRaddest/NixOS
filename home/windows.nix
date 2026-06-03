{ ... }:

{
  flake.lib.homeModules.windows =
    { self, pkgs, ... }:

    let
      windows-vm = pkgs.writeShellScriptBin "windows-vm" (
        builtins.readFile "${self}/config/windows/scripts/windows.sh"
      );
      windows-vm-rdp = pkgs.writeShellScriptBin "windows-vm-rdp" (
        builtins.readFile "${self}/config/windows/scripts/windows-vm-rdp.sh"
      );
      windows-vm-start = pkgs.writeShellScriptBin "windows-vm-start" (
        builtins.readFile "${self}/config/windows/scripts/windows-vm-start.sh"
      );
      windows-install = pkgs.writeShellScriptBin "windows-install" (
        builtins.readFile "${self}/config/windows/scripts/windows-install.sh"
      );
      windows-uninstall = pkgs.writeShellScriptBin "windows-uninstall" (
        builtins.readFile "${self}/config/windows/scripts/windows-uninstall.sh"
      );
    in
    {
      xdg.configFile."windows/docker-compose.yaml".source = "${self}/config/windows/docker-compose.yaml";

      home.packages = with pkgs; [
        docker-compose
        freerdp
        jq

        windows-vm
        windows-vm-rdp
        windows-vm-start

        windows-install
        windows-uninstall
      ];
    };
}
