{ config, pkgs, ... }:

let
  # Define a custom Hyprland package built from git
  hyprland = pkgs.stdenv.mkDerivation {
    name = "hyprland";
    src = pkgs.fetchFromGitHub {
      owner = "hyprwm";
      repo = "Hyprland";
      rev = "master"; # Replace this with the desired commit or branch
      sha256 = lib.fakeSha256; # Run `nix-build` to get the correct hash
    };
    buildInputs = [
      pkgs.meson
      pkgs.ninja
      pkgs.pkg-config
      pkgs.wayland
      pkgs.libxcb
      pkgs.pixman
      pkgs.glew
    ];
  };

  # define the custom hyprland-hy3 plugin from git
  hy3plugin = pkgs.stdenv.mkDerivation {
    name = "hy3plugin";
    src = pkgs.fetchFromGitHub {
      owner = "hyprland-community";
      repo = "hyprland-hy3";
      rev = "main";
      sha256 = lib.fakeSha256;
    };
    # ensure it builds against the custom hyprland package
    buildInputs = [ hyprland ];
  };

in {

  # enable users, groups, and base system settings
  users.users.yourusername = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ]; # Add groups as needed
    openssh.authorizedKeys.keys = [ "your-ssh-public-key" ];
  };

  # system-wide packages
  environment.systemPackages = with pkgs; [
    # general utilities
    apparmor
    diffutils
    fakeroot
    glibc-locales
    man-db
    neovim
    networkmanager
    wget
    zsh
    zsh-completions
    fzf
    tmux
    git
    fd
    glow
    python3
    python3Packages.pip
    python3Packages.pipx

    # gui/wayland-related
    papirus-icon-theme
    pipewire
    pipewire-alsa
    pipewire-jack
    pipewire-pulse
    wireplumber
    alacritty
    waybar
    dunst
    rofi
    brightnessctl
    grim

    # gaming
    steam
    gamemode
    lutris

    # media drivers
    intel-media-driver
    libva-utils
    radeontop

    # hyprland from git
    hyprland
    hy3plugin
  ];

  # Enable services and systemd setup
  services = {
    # core services
    systemd.networkd.enable = true;
    systemd.resolved.enable = true;

    # wayland display manager (e.g., gdm)
    gdm.enable = true;

    # networkmanager for connectivity
    networkmanager.enable = true;

    # podman for containers
    podman = {
      enable = true;
      userSocket = true;
    };

    # enable ssh
    #openssh.enable = true;

    # plymouth for boot splash
    plymouth.enable = true;

    # pipewire for audio
    pipewire = {
      enable = true;
      alsa.enable = true;
      jack.enable = true;
      pulseaudio.enable = true;
    };

    # flatpak for additional packaging
    flatpak.enable = true;
  };

  # extra kernel settings for tpm tools or apparmor
  boot.kernelModules = [ "tpm" "tpm_tis" "tpm_tis_spi" ];
  security = {
    apparmor = {
      enable = true;
      supportResolved = true;
    };
  };

  # fonts
  fonts.fontDir.enable = true;
  fonts.fonts = [
    pkgs.noto-fonts
    pkgs.noto-fonts-emoji
    pkgs.noto-fonts-cjk
    pkgs.ttf-font-awesome
    pkgs.nerd-fonts-terminess-ttf
  ];

  # Hyprland as the session (if not using GDM)
  services.xserver = {
    enable = true;
    windowManager.hyprland.enable = true;
  };

  # Gaming optimization
  services.steam.enable = true;

  # Flatpak setup
  environment.variables = {
    XDG_DATA_DIRS = "${pkgs.flatpak}/share";
  };

  # Miscellaneous options (e.g., shell, locales)
  programs.zsh.enable = true;
  programs.neovim.enable = true;
  programs.flatpak.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Etc/UTC";

  # Advanced system tweaks
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
}
