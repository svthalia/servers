{
  config = {
    nix = {
      # This is required to be able to use nix-copy-closure
      trustedUsers = [ "root" "@wheel" ];
    };

    # Because user directories aren't saved, sudo doesn't remember that we have seen the lecture
    # Disabling the lecture allows us to not see it ever
    security.sudo = {
      wheelNeedsPassword = false;
      extraConfig = ''
        Defaults lecture = never
      '';
    };

    # Users are purely defined by this configuration file, so password changes
    # will be reset when a new version is deployed
    users.mutableUsers = false;
    users.users.jelle = {
      isNormalUser = true;
      description = "Jelle Besseling";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICunYiTe1MOJsGC5OBn69bewMBS5bCCE1WayvM4DZLwE jelle@Jelles-Macbook-Pro.local"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID+/7ktPyg4lYL0b6j3KQqfVE6rGLs5hNK3Q175th8cq jelle@foon"
      ];
      hashedPassword = "$6$tWSq6JiZN4g$gKJw0DsTTCMi0Hb0.trq/9GIT2qbkJxdkYA2ppBtLUmbuynNUJ34DVbT3.XPTmsytcCG6Xks3nvJzgbUuex4W1";
    };
    users.users.wouter = {
      isNormalUser = true;
      description = "Wouter Doeland";
      extraGroups = [ "wheel" ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEblHIN5uaooHczkiqbXa6V7H7bfhgGTVLKA0sUggBkP wouter@wouterdoeland.nl"
      ];
    };
  };
}
