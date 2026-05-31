{ pkgs, ... }:

let
  windowsScript = pkgs.writeShellScriptBin "windows-vm" (builtins.readFile ../config/windows/scripts/windows.sh);
  windowsInstallScript = pkgs.writeShellScriptBin "windows-install" (builtins.readFile ../config/windows/scripts/windows-install.sh);
  windowsUninstallScript = pkgs.writeShellScriptBin "windows-uninstall" (builtins.readFile ../config/windows/scripts/windows-uninstall.sh);
  windowsRdpScript = pkgs.writeShellScriptBin "windows-vm-rdp" (builtins.readFile ../config/windows/scripts/windows-vm-rdp.sh);
  windowsStartScript = pkgs.writeShellScriptBin "windows-vm-start" (builtins.readFile ../config/windows/scripts/windows-vm-start.sh);
in
{
  xdg.configFile."windows/docker-compose.yaml".source = ../config/windows/docker-compose.yaml;

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
