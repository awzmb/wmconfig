{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  nix.settings.experimental-features = [ "flakes" "nix-command" ];

  # set the default editor to neovim
  environment.variables.EDITOR = "nvim";

  # bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # use latest kernel
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # the touchpad uses i²c, so ps/2 is unnecessary
  boot.blacklistedKernelModules = [ "psmouse" ];

  # plymouth
  boot.plymouth.enable = true;
  boot.plymouth.theme = "bgrt";
  boot.initrd.verbose = false;
  boot.consoleLogLevel = 0;
  #boot.kernelParams = [ "quiet" "udev.log_level=0" ];

  #security.tpm2.enable = true;
  # expose /run/current-system/sw/lib/libtpm2_pkcs11.so
  #security.tpm2.pkcs11.enable = true;
  # TPM2TOOLS_TCTI and TPM2_PKCS11_TCTI env variables
  #security.tpm2.tctiEnvironment.enable = true;

  networking.hostName = "nixos";

  # enable networking
  networking.networkmanager.enable = true;

  # set your time zone.
  time.timeZone = "Europe/Berlin";

  # select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

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
  #console.keyMap = "dvorak";

  # enable cups to print documents.
  services.printing.enable = false;

  # enable sound with pipewire.
  hardware.pulseaudio.enable = false;
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
    terminus_font
    terminus_font_ttf
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
    blueman

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


  # git configuration
  programs.git = {
    enable = true;
    userEmail = "bundschuh.dennis@gmail.com";
    userName = "awzmb";
  };

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
  #services.thermald.enable = lib.mkDefault true;

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
