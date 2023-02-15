{pkgs,...}: {
  home = {
    username = "michael";
    homeDirectory = "/home/michael/";
    home.packages = with pkgs; [
        openssh
        git
        kmail
        akonadi
        tdesktop
    ];
  };
  programs.home-manager.enable = true;
  programs.git.enable = true;
  programs.zsh.enable = true;

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };

  home.stateVersion = "22.11";
}
