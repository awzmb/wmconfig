# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # if you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # you can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  nixpkgs = {
    # you can add overlays here
    overlays = [
      # add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # you can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # configure your nixpkgs instance
    config = {
      allowUnfree = true;
    };
  };

  home = {
    username = "awzm";
    homeDirectory = "/home/awzm";
  };

  gtk = {
    enable = true;
    font.name = "Terminess Nerd Font 12";
    theme = {
      name = "Qogir-Dark";
      package = pkgs.qogir-theme;
    };

    gtk3.extraConfig = {
      Settings = ''
       gtk-application-prefer-dark-theme=1
       gtk-font-name=Terminess Nerd Font
     '';
    };

    gtk4.extraConfig = {
      Settings = ''
       gtk-application-prefer-dark-theme=1
       gtk-font-name=Terminess Nerd Font
     '';
    };
  };

  # Add stuff for your user as you see fit:
  # home.packages = with pkgs; [ steam ];

  programs.neovim.enable = true;

  # Enable home-manager and git
  programs.home-manager.enable = true;

  # git configuration
  programs.git = {
    enable = true;
    extraConfig = {
      user.name = "awzmb";
      user.email = "bundschuh.dennis@gmail.com";
      init.defaultBranch = "main";
    };
  };

  # nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/faq/when_do_i_update_stateversion
  home.stateVersion = "24.11";
}
