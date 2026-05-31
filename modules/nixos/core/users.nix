{ ... }:

{
  users.users.cdt = {
    isNormalUser = true;
    description = "Connor du Toit";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" "kvm" ];
  };

  security.sudo.wheelNeedsPassword = true;
  security.polkit.enable = true;
}
