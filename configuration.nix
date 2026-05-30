{ config, pkgs, ... }:

{
  # ── Nix ────────────────────────────────────────────────────────────────── #
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 10d";
  };
  nixpkgs.config.allowUnfree = true;

  # ── Boot ───────────────────────────────────────────────────────────────── #
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelModules = [ "btusb" ];

  # ── System ─────────────────────────────────────────────────────────────── #
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  time.timeZone = "Africa/Johannesburg";
  i18n.defaultLocale = "en_ZA.UTF-8";
  services.xserver.xkb.layout = "za";

  # ── Users ──────────────────────────────────────────────────────────────── #
  users.users.cdt = {
    isNormalUser = true;
    description = "Connor du Toit";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" "docker" ];
  };

  security.sudo.wheelNeedsPassword = true;
  security.polkit.enable = true;

  # ── Graphics ───────────────────────────────────────────────────────────── #
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # ── Bluetooth ───────────────────────────────────────────────────────────── #
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  # Unblock bluetooth on system startup
  systemd.services.bluetooth-unblock = {
    description = "Unblock Bluetooth with rfkill";
    wantedBy = [ "multi-user.target" ];
    after = [ "bluetooth.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
    };
  };

  # ── Power ──────────────────────────────────────────────────────────────── #
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  services.upower.enable = true;
  services.logind.settings.Login = {
    HandlePowerKey = "ignore";
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
  };
  services.udev.extraRules = ''
    ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver"
    ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance"
  '';

  # ── Printing ───────────────────────────────────────────────────────────── #
  services.printing.enable = true;

  # ── Docker ─────────────────────────────────────────────────────────────── #
  virtualisation.docker.enable = true;

  # ── Audio ──────────────────────────────────────────────────────────────── #
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };


  # ── Hyprland & Desktop Portals ─────────────────────────────────────────── #
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.bash}/bin/bash --login -c 'uwsm start hyprland-uwsm.desktop'";
      user = "cdt";
    };
  };

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.hyprlock = { };

  environment.sessionVariables = {
    GTK_USE_PORTAL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
    config.common.default = [ "hyprland" "gtk" ];
    config.common."org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
    config.common."org.freedesktop.impl.portal.Settings" = [ "gtk" ];
  };

  # ── Fonts ──────────────────────────────────────────────────────────────── #
  fonts.packages = with pkgs; [
    cantarell-fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    font-awesome
  ];

  # ── Packages ───────────────────────────────────────────────────────────── #
  environment.systemPackages = with pkgs; [
    # Hyprland utilities
    hyprpicker
    lxqt.lxqt-policykit # Replaced polkit_gnome with a cleaner systemd-friendly agent
    grim
    slurp
    wl-clipboard
    pamixer
    wiremix
    libnotify
    playerctl
    brightnessctl
    home-manager

    # Shell
    quickshell

    # Bluetooth / Wifi
    bluetui
    impala
    iwd

    # Terminal / CLI
    git
    ripgrep
    fd
    jq
    bat
    eza
    zoxide
    fzf
    fastfetch
    tldr
    tree
    unzip

    # Dev
    python3
    nodejs
    claude-code
    pi-coding-agent
    nixd
    direnv
    nix-direnv
    nixfmt

    # Apps
    firefox
    nautilus
    mpv
    imv
    localsend

    # System tools
    pciutils
    usbutils
  ];

  system.stateVersion = "26.05";
}
