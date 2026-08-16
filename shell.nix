{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  packages = [
    pkgs.quickshell
    pkgs.qt6.qtdeclarative
    pkgs.qt6Packages.qt6ct
  ];
}
