{ ... }:

{
  flake.lib.homeModules.windows =
    { self, pkgs, ... }:

    let
      windowsScript = pkgs.writeShellScriptBin "windows-vm"
        (builtins.readFile "${self}/assets/windows/scripts/windows.sh");
      windowsInstallScript = pkgs.writeShellScriptBin "windows-install"
        (builtins.readFile "${self}/assets/windows/scripts/windows-install.sh");
      windowsUninstallScript = pkgs.writeShellScriptBin "windows-uninstall"
        (builtins.readFile "${self}/assets/windows/scripts/windows-uninstall.sh");
      windowsRdpScript = pkgs.writeShellScriptBin "windows-vm-rdp"
        (builtins.readFile "${self}/assets/windows/scripts/windows-vm-rdp.sh");
      windowsStartScript = pkgs.writeShellScriptBin "windows-vm-start"
        (builtins.readFile "${self}/assets/windows/scripts/windows-vm-start.sh");
    in
    {
      xdg.configFile."windows/docker-compose.yaml".source =
        "${self}/assets/windows/docker-compose.yaml";

      home.packages = with pkgs; [
        docker-compose
        freerdp
        windowsScript
        windowsInstallScript
        windowsUninstallScript
        windowsRdpScript
        windowsStartScript
      ];
    }
;
}
