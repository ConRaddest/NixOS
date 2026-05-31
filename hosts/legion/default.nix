{ ... }:

# ── still to do: ────────────────────────────────────────────────────────────────── #
# 6. Firewall / network hardening
# 8. Backup strategy
# 10. Default apps / MIME associations
# 11. GTK / Qt theming polish
# 12. Clipboard / screenshot history
# 13. Notification daemon polish
# 14. Power / laptop behavior - laptop lid closing (monitor disabling management)
# 15. Monitor / workspace robustness
# 16. Development environment toolchains
# 17. System recovery / maintenance workflow
# 18. Customise fastfetch

{
  imports = [
    ./hardware.nix
    ../../modules/nixos
  ];

  networking.hostName = "legion";

  system.stateVersion = "26.05";
}
