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
  programs.ssh.startAgent = true;

  # ── Hardware ───────────────────────────────────────────────────────────── #
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  systemd.services.systemd-rfkill.enable = false;
  systemd.sockets.systemd-rfkill.enable = false;
  services.blueman.enable = false;

  # ── Power ──────────────────────────────────────────────────────────────── #
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  services.upower.enable = true;
  services.logind.settings.Login.HandlePowerKey = "ignore";
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
  };

  services.xdg.portal = {
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
    gtk3

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
