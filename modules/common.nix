{ pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs; [
      vim
      htop
    ];
  };
}
