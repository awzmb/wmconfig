#{ config, pkgs, ... }:

#let
  ## Define a custom Hyprland package built from git
  #hyprland = pkgs.stdenv.mkDerivation {
    #name = "hyprland";
    #src = pkgs.fetchFromGitHub {
      #owner = "hyprwm";
      #repo = "Hyprland";
      #rev = "master"; # Replace this with the desired commit or branch
      #sha256 = lib.fakeSha256; # Run `nix-build` to get the correct hash
    #};
    #buildInputs = [
      #pkgs.meson
      #pkgs.ninja
      #pkgs.pkg-config
      #pkgs.wayland
      #pkgs.libxcb
      #pkgs.pixman
      #pkgs.glew
    #];
  #};

  ## define the custom hyprland-hy3 plugin from git
  #hy3plugin = pkgs.stdenv.mkDerivation {
    #name = "hy3plugin";
    #src = pkgs.fetchFromGitHub {
      #owner = "hyprland-community";
      #repo = "hyprland-hy3";
      #rev = "main";
      #sha256 = lib.fakeSha256;
    #};
    ## ensure it builds against the custom hyprland package
    #buildInputs = [ hyprland ];
  #};

#in {

  ## enable users, groups, and base system settings
  #users.users.yourusername = {
    #isNormalUser = true;
    #extraGroups = [ "wheel" "networkmanager" ]; # Add groups as needed
    #openssh.authorizedKeys.keys = [ "your-ssh-public-key" ];
  #};

  ## system-wide packages
  #environment.systemPackages = with pkgs; [
    ## general utilities
    #apparmor
    #diffutils
    #fakeroot
    #glibc-locales
    #man-db
    #neovim
    #networkmanager
    #wget
    #zsh
    #zsh-completions
    #fzf
    #tmux
    #git
    #fd
    #glow
    #python3
    #python3Packages.pip
    #python3Packages.pipx

    ## gui/wayland-related
    #papirus-icon-theme
    #pipewire
    #pipewire-alsa
    #pipewire-jack
    #pipewire-pulse
    #wireplumber
    #alacritty
    #waybar
    #dunst
    #rofi
    #brightnessctl
    #grim

    ## gaming
    #steam
    #gamemode
    #lutris

    ## media drivers
    #intel-media-driver
    #libva-utils
    #radeontop

    ## hyprland from git
    #hyprland
    #hy3plugin
  #];

  ## Enable services and systemd setup
  #services = {
    ## core services
    #systemd.networkd.enable = true;
    #systemd.resolved.enable = true;

    ## wayland display manager (e.g., gdm)
    #gdm.enable = true;

    ## networkmanager for connectivity
    #networkmanager.enable = true;

    ## podman for containers
    #podman = {
      #enable = true;
      #userSocket = true;
    #};

    ## enable ssh
    ##openssh.enable = true;

    ## plymouth for boot splash
    #plymouth.enable = true;

    ## pipewire for audio
    #pipewire = {
      #enable = true;
      #alsa.enable = true;
      #jack.enable = true;
      #pulseaudio.enable = true;
    #};

    ## flatpak for additional packaging
    #flatpak.enable = true;
  #};

  ## extra kernel settings for tpm tools or apparmor
  #boot.kernelModules = [ "tpm" "tpm_tis" "tpm_tis_spi" ];
  #security = {
    #apparmor = {
      #enable = true;
      #supportResolved = true;
    #};
  #};

  ## fonts
  #fonts.fontDir.enable = true;
  #fonts.fonts = [
    #pkgs.noto-fonts
    #pkgs.noto-fonts-emoji
    #pkgs.noto-fonts-cjk
    #pkgs.ttf-font-awesome
    #pkgs.nerd-fonts-terminess-ttf
  #];

  ## Hyprland as the session (if not using GDM)
  #services.xserver = {
    #enable = true;
    #windowManager.hyprland.enable = true;
  #};

  ## Gaming optimization
  #services.steam.enable = true;

  ## Flatpak setup
  #environment.variables = {
    #XDG_DATA_DIRS = "${pkgs.flatpak}/share";
  #};

  ## Miscellaneous options (e.g., shell, locales)
  #programs.zsh.enable = true;
  #programs.neovim.enable = true;
  #programs.flatpak.enable = true;
  #i18n.defaultLocale = "en_US.UTF-8";
  #time.timeZone = "Etc/UTC";

  ## Advanced system tweaks
  #boot.loader = {
    #systemd-boot.enable = true;
    #efi.canTouchEfiVariables = true;
  #};
#}

{ config, pkgs, lib, ... }:
{
  imports =
    [
      ./hardware-configuration.nix
      ./flatpak.nix
    ];

  # use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # the touchpad uses i²c, so ps/2 is unnecessary
  boot.blacklistedKernelModules = [ "psmouse" ];

  # bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.useOSProber = true;
  #boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # plymouth
  boot.plymouth.enable = true;
  boot.plymouth.theme = "bgrt";
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 0;
  boot.kernelParams = [ "quiet" "udev.log_level=0" ];

  # setup keyfile
  boot.initrd.secrets = {
    "/boot/crypto_keyfile.bin" = null;
  };

  boot.loader.grub.enableCryptodisk = true;

  boot.initrd.luks.devices."luks-f4cbd3a3-88a9-46f8-98d1-d8f6f6af4920".keyFile = "/boot/crypto_keyfile.bin";

  security.tpm2.enable = true;
  # expose /run/current-system/sw/lib/libtpm2_pkcs11.so
  security.tpm2.pkcs11.enable = true;
  # TPM2TOOLS_TCTI and TPM2_PKCS11_TCTI env variables
  security.tpm2.tctiEnvironment.enable = true;

  networking.hostName = "nixos";
  #networking.wireless.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # enable networking
  networking.networkmanager.enable = true;

  # set your time zone.
  time.timeZone = "Europe/Berlin";

  # select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # enable the gnome desktop environment.
  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    desktopManager.gnome.enable = true;
  };

  # configure console keymap
  console.keyMap = "dvorak";

  # enable cups to print documents.
  services.printing.enable = false;

  # enable sound with pipewire.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # define a user account. don't forget to set a password with ‘passwd’.
  users.users.awzm = {
    isNormalUser = true;
    description = "awzm";
    extraGroups = [ "networkmanager" "wheel" "tss" ];
    packages = with pkgs; [
    #  thunderbird
    ];
#    gtk = {
#      enable = true;
#      font.name = "Terminess Nerd Font 12";
#      theme = {
#        name = "Qogir-Dark";
#        package = pkgs.qogir-theme;
#      };
#
#      gtk3.extraConfig = {
#        Settings = ''
#         gtk-application-prefer-dark-theme=1
#         gtk-font-name=Terminess Nerd Font
#       '';
#      };
#
#      gtk4.extraConfig = {
#        Settings = ''
#         gtk-application-prefer-dark-theme=1
#         gtk-font-name=Terminess Nerd Font
#       '';
#      };
#    };
  };

  # allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # list packages installed in system profile. to search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # shell tools
    neovim
    wget
    curl
    eza
    bat
    zsh
    zsh-completions
    fzf
    tmux
    pass
    w3m
    calc
    git
    git-lfs
    git-hub
    git-get
    gitleaks
    delta
    fd
    nodejs
    yarn
    htop
    mpv
    calcurse
    yamllint
    glow
    distrobox
    unrar
    wireguard-tools
    netcat
    termshark
    jwt-cli
    zip
    ctags
    cscope
    miller
    pass
    pass-git-helper
    openssl

    # languages
    python313
    pylint
    go
    gopls

    # networking
    networkmanager_dmenu
    networkmanager-vpnc
    networkmanager-openvpn
    networkmanager-openconnect
    networkmanagerapplet

    # security
    apparmor-utils
    apparmor-parser
    apparmor-profiles
    apparmor-bin-utils
    apparmor-kernel-patches
    libapparmor

    # fonts
    terminus-nerdfont

    # plymouth
    plymouth
    #adi1090x-plymouth-themes
    nixos-bgrt-plymouth

    # desktop
    wl-clipboard
    wl-clip-persist
    brightnessctl
    cliphist
    gammastep
    yank
    rofi-wayland
    dunst
    pavucontrol
    alacritty
    kitty
    nwg-displays
    nwg-look
    nwg-menu
    nwg-launchers
    grim
    papirus-icon-theme
    qogir-theme
    libva
    libva1
    libva-utils
    libva-vdpau-driver

    # sway and hyprland
    waybar
    sway
    swaybg
    swayimg
    swaylock
    swayidle
    swaytools
    xdg-desktop-portal-wlr
    hyprland
    hypridle
    hyprcursor
    hyprlock
    hypridle
    hyprkeys
    hyprshot
    xdg-desktop-portal-hyprland
    hyprland-protocols
    hyprlandPlugins.hy3
    hyprlandPlugins.hyprgrass
    hyprlandPlugins.hyprfocus

    # gaming
    steam
    lutris
    gamescope
    gamemode
    mangohud

    # camera
    v4l-utils

    # cloud engineering
    google-cloud-sdk
    google-cloud-sdk-gce
    google-cloud-sql-proxy
    google-cloud-bigtable-tool
  ];

  #hardware.enableRedistributableFirmware = true

  hardware.bluetooth.enable = true;
  # powers up the default Bluetooth controller on boot
  hardware.bluetooth.powerOnBoot = true;

  hardware = {
    pulseaudio.enable = false;

    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiVdpau
        libvdpau-va-gl
        vpl-gpu-rt
      ];
    };
  };

  # zsh
  programs.zsh = {
    enable = true;
  };

  programs.sway.enable = true;
  programs.hyprland.enable = true;

  #hardware.intelgpu = {
  #  driver = lib.mkIf (lib.versionAtLeast config.boot.kernelPackages.kernel.version "6.8") "xe";
  #  vaapiDriver = "intel-media-driver";
  #};

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # recommended in nixos/nixos-hardware#127
  services.thermald.enable = lib.mkDefault true;

  services.flatpak.enable = true;
  services.fwupd.enable = true;

  # enable the openssh daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?

}
