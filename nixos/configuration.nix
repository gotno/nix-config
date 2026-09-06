{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    ./hardware-configuration.nix
    inputs.apple-silicon.nixosModules.apple-silicon-support

    # If you want to use modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      # Opinionated: disable global registry
      flake-registry = "";

      trusted-users = [ "root" "ont" ];
    };
    # Opinionated: disable channels
    channel.enable = false;
  };

  hardware.asahi.enable = true;
  hardware.asahi.setupAsahiSound = true;
  hardware.asahi.peripheralFirmwareDirectory = pkgs.runCommand "asahi-firmware" {} ''
    mkdir -p $out
    cp ${pkgs.requireFile {
      name = "firmware.cpio";
      sha256 = "sha256-srBmltdH9QxgIbKONBEkGQak1zRAuI0NFajFjfulIbk=";
      message = "need firmware.cpio via: nix-store --add-fixed sha256 /path/to/firmware.cpio";
    }} $out/firmware.cpio
  '';

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.kernel.sysctl = {
    "kernel.printk" = "3 4 1 7";
  };
  services.journald = {
    extraConfig = ''
      ForwardToConsole=no
      ForwardToWall=no
    '';
  };

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  # networking
  networking.hostName = "gtnix";
  # configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };
  networking.nameservers = ["1.1.1.1" "1.0.0.1"];
  services.resolved = {
    enable = true;
    domains = ["~."];
    fallbackDns = ["1.1.1.1" "1.0.0.1"];
    dnsovertls = "true";
  };

  security.sudo.enable = true;
  users.users = {
    ont = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "seat"
        "input"
      ];
    };
  };

  programs.bash.enable = true;

  environment.systemPackages = [
    pkgs.upower

    pkgs.htop
    pkgs.btop
    pkgs.tree
    pkgs.gnugrep
    pkgs.gnupg
    pkgs.silver-searcher
    pkgs.ripgrep
    pkgs.fd
    pkgs.wget
    pkgs.ranger
    pkgs.tmux

    pkgs.home-manager
  ];
  # This setups a SSH server. Very important if you're setting up a headless system.
  # Feel free to remove if you don't need it.
  # services.openssh = {
  #   enable = true;
  #   settings = {
  #     # Opinionated: forbid root login through SSH.
  #     PermitRootLogin = "no";
  #     # Opinionated: use keys only.
  #     # Remove if you want to SSH using passwords
  #     PasswordAuthentication = false;
  #   };
  # };

  # use interception-tools to map capslock to hold=ctrl, tap=esc
  services.interception-tools = {
    enable = true;
    plugins = [ pkgs.interception-tools-plugins.caps2esc ];
    udevmonConfig = ''
      - JOB: "${pkgs.interception-tools}/bin/intercept -g $DEVNODE | ${pkgs.interception-tools-plugins.caps2esc}/bin/caps2esc -m 1 | ${pkgs.interception-tools}/bin/uinput -d $DEVNODE"
        DEVICE:
          EVENTS:
            EV_KEY: [KEY_CAPSLOCK, KEY_ESC]
    '';
  };

  # backlight
  programs.light.enable = true;
  services.actkbd = {
    enable = true;
    bindings = [
      { keys = [ 225 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -A 10"; }
      { keys = [ 224 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/light -U 10"; }
    ];
  };
  services.upower.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "25.11";
}
