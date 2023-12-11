# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, envs, ... }:
{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";

  boot.kernelModules = ["v4l2loopback"];
  boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  # security.pki.certificateFiles = [ /home/michael/Descargas/YandexInternalRootCA.crt ];

  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
    magicOrExtension = ''\x7fELF....AI\x02'';
  };

  nixpkgs.config.packageOverrides =  super: let self = super.pkgs; in {

     neovim = super.neovim.override {
       withPython3 = true;
     };

     # For akonadi with posgres as default
     #mysqlSupport = false;
     postgresSupport = true;
     defaultDriver = "POSTGRES";
  };

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  networking.hostName = "ssmike-thinkpad"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Argentina/Buenos_Aires";

  # Select internationalisation properties.
  #i18n.defaultLocale = "en_US.UTF-8";
  i18n.defaultLocale = "es_AR.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_AR.UTF-8";
    LC_IDENTIFICATION = "es_AR.UTF-8";
    LC_MEASUREMENT = "es_AR.UTF-8";
    LC_MONETARY = "es_AR.UTF-8";
    LC_NAME = "es_AR.UTF-8";
    LC_NUMERIC = "es_AR.UTF-8";
    LC_PAPER = "es_AR.UTF-8";
    LC_TELEPHONE = "es_AR.UTF-8";
    LC_TIME = "es_AR.UTF-8";
  };
  i18n.supportedLocales = ["all"];

  services.xserver.enable = true;
  # services.xserver.displayManager.defaultSession = "plasmawayland";
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5 = {
    enable = true;
  };

  environment.plasma5.excludePackages = with pkgs.libsForQt5; [kwrited];

  hardware.bluetooth.enable = true;
  # Configure keymap in X11
  services.xserver = {
    layout = "us,ru";
    xkbVariant="altgr-intl,";
    xkbOptions = "grp:caps_toggle,lv3:switch,grp_led:caps";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
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

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.michael = {
    isNormalUser = true;
    description = "Михаил";
    extraGroups = [ "networkmanager" "wheel" "video" "docker" "tss"];
    shell = pkgs.zsh;
    packages = with pkgs;
    let my-pass = (pass-nodmenu.withExtensions (ext: with ext; [pass-otp pass-genphrase pass-import]));
    in [
      (firefox.override {extraNativeMessagingHosts = [ (passff-host.override { pass = my-pass; }) ];})
      my-pass

      alacritty
      neovim neovim-qt meld direnv
      openssh
      tdesktop
      pinentry
      networkmanager-openvpn
      ccid
      kate
      kmail
      ktorrent
      vlc
      zoom-us
      libreoffice-qt
      wine wineWowPackages.stable
      droidcam
      telegram-desktop
      discord
    ] ++  (with pkgs.libsForQt5; [
      kasts
      kalendar
      kleopatra
      spectacle
      kdeconnect-kde
      kdepim-addons
      filelight
      kaccounts-providers
      korganizer
      ark
      akregator
      konversation
      neochat
      krdc
      kid3
      kamoso
      ksystemlog
      ghostwriter
      knotes
    ]);
  };

  programs.steam.enable = true;
  hardware.opengl.driSupport32Bit = true;

  programs.kdeconnect.enable = true;

  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "michael";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ] ++ envs.dev_common;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;

  programs.zsh.enable = true;

  programs.nix-ld = {
     enable = true;
     libraries = [ pkgs.libxcrypt pkgs.libxcrypt-legacy pkgs.zlib ];
  };

  programs.dconf.enable = true;
  programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
     pinentryFlavor = "qt";
  };
  services.pcscd.enable = true;
  
  services.openvpn.servers = {
     yandex = {
         config = '' config /etc/openvpn/client/yandex.conf '';
         autoStart = true;
         updateResolvConf = true;
     };
  };

  systemd.extraConfig = ''
    RebootWatchdogSec=20s
    ShutdownWatchdogSec=20s
  '';

  
  environment.shells = with pkgs; [ zsh bash ];
  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  virtualisation.docker = {
     enable = true;
     rootless = {
        enable = true;
        setSocketVariable = true;
    };
  };

  services.flatpak.enable = true;

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
  system.stateVersion = "22.11"; # Did you read the comment?

}
