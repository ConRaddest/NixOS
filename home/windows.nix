{ ... }:

{
  flake.lib.homeModules.windows =
    { self, pkgs, ... }:

    let
      windows-vm = pkgs.writeShellScriptBin "windows-vm" (
        builtins.readFile "${self}/scripts/windows/windows.sh"
      );
      windows-vm-rdp = pkgs.writeShellScriptBin "windows-vm-rdp" (
        builtins.readFile "${self}/scripts/windows/windows-vm-rdp.sh"
      );
      windows-vm-start = pkgs.writeShellScriptBin "windows-vm-start" (
        builtins.readFile "${self}/scripts/windows/windows-vm-start.sh"
      );
      windows-install = pkgs.writeShellScriptBin "windows-install" (
        builtins.readFile "${self}/scripts/windows/windows-install.sh"
      );
      windows-uninstall = pkgs.writeShellScriptBin "windows-uninstall" (
        builtins.readFile "${self}/scripts/windows/windows-uninstall.sh"
      );
    in
    {
      xdg.desktopEntries.windows-vm = {
        name = "Windows";
        comment = "Launch Windows virtual machine";
        exec = "windows-vm";
        icon = "windows-vm";
        terminal = false;
        type = "Application";
        categories = [ "System" ];
      };

      home.file = {
        # --- Windows 11 ---
        ".local/share/icons/hicolor/scalable/apps/windows-vm.svg".text = ''
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
            <path fill="#0078d4" d="M67.328 67.331h60.669V128H67.328zm-67.325 0h60.669V128H.003zM67.328 0h60.669v60.669H67.328zM.003 0h60.669v60.669H.003z"/>
          </svg>
        '';

      };

      xdg.configFile."windows/docker-compose.yaml".source = "${self}/config/windows/docker-compose.yaml";

      home.packages = with pkgs; [
        docker-compose
        freerdp
        qemu

        windows-vm
        windows-vm-rdp
        windows-vm-start

        windows-install
        windows-uninstall
      ];
    };
}
