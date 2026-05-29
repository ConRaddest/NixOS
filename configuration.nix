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
  # boot.consoleLogLevel = 0;
  # boot.kernelParams = [ "quiet" "udev.log_level=3" ];

  # ── System ─────────────────────────────────────────────────────────────── #
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
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

  # ── Hyprland ───────────────────────────────────────────────────────────── #
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    withUWSM = true;
  };

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.bash}/bin/bash -lc 'sleep 1; ${pkgs.ncurses}/bin/clear; exec ${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd \"uwsm start hyprland-uwsm.desktop\"'";
      user = "greeter";
    };
  };

  services.gnome.gnome-keyring.enable = true;
  services.gnome.gcr-ssh-agent.enable = false;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.hyprlock = { };

  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
    GTK_USE_PORTAL = "1";
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
    ];
    config.common.default = [ "hyprland" "gtk" ];
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
  # kitty, btop, yazi, hypridle, hyprlock, hyprpaper are managed by home-manager
  environment.systemPackages = with pkgs; [
    # Hyprland utilities
    hyprpicker
    polkit_gnome
    grim
    slurp
    wl-clipboard
    pamixer
    wiremix
    libnotify
    playerctl
    brightnessctl

    # Shell
    quickshell

    # Bluetooth
    bluetui

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
