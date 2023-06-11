{config, pkgs, ...}:
{
  home.stateVersion = "23.11";
  home.username = "michael";
  home.homeDirectory = "/home/michael";

  programs.home-manager.enable = true;
}
