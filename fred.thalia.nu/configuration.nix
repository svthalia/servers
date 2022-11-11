# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, nix, ... }:

let
  nixServe = rec {
    keyDirectory = "/persist/keys/nix-serve";

    privateKey = "${keyDirectory}/nix-serve.sec";

    publicKey = "${keyDirectory}/nix-serve.pub";
  };

in

{
  imports =
    [
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../modules/persistence.nix
      ../modules/users.nix
      ../modules/common.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.grub.extraConfig = "serial --unit=1 --speed=115200 --word=8 --parity=no --stop=1";
  boot.kernelParams = [
    "console=ttyS1,115200n8"
  ];

  networking.hostName = "fred"; # Define your hostname.

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.eno1.useDHCP = false;
  networking.interfaces.eno3.useDHCP = false;
  networking.interfaces.eno4.useDHCP = false;

  # Needed for zfs
  networking.hostId = "718ec992";

  networking.defaultGateway = "131.174.41.1";
  networking.nameservers = [
    "131.174.30.40"
    "131.174.16.131"
  ];
  networking.interfaces.eno2 = {
    useDHCP = false;
    tempAddress = "disabled";
    ipv4.addresses = [
      {
        address = "131.174.41.17";
        prefixLength = 25;
      }
    ];
  };

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
  nix.package = nix.defaultPackage.x86_64-linux;

  environment.systemPackages = with pkgs; [
    git
  ];

  # virtualisation.libvirtd.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    hostKeys = [
      {
        path = "/persist/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  nixpkgs.config.allowUnfree = true;
  services.minecraft-server = {
    enable = true;
    dataDir = "/persist/minecraft";
    openFirewall = true;
    eula = true;
    serverProperties = {
      server-port = 80;
    };
  };
  systemd.services.minecraft-server.serviceConfig.UMask = "0002";
  systemd.services.minecraft-server.serviceConfig.WorkingDirectory = lib.mkForce null;
  systemd.services.minecraft-server.serviceConfig.ExecStartPre = lib.mkForce null;
  systemd.services.minecraft-server.serviceConfig.ExecStart = lib.mkForce (pkgs.writeScript "minecraft-start" ''
    #! ${pkgs.runtimeShell}
    cd /persist/minecraft
    ${pkgs.jre_headless}/bin/java -Xmx8192M -Xms8192M -jar /persist/minecraft/server.jar nogui
  '');
  users.users.minecraft.createHome = lib.mkForce false;

  users.users.minecraftadmin = {
    isNormalUser = true;
    home = "/persist/minecraft";
    description = "Rico, Lars and Thijs";
    createHome = false;
    group = "minecraft";
    extraGroups = [ "systemd-journal" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICunYiTe1MOJsGC5OBn69bewMBS5bCCE1WayvM4DZLwE jelle@Jelles-Macbook-Pro.local"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCaSkNFET6TQkceX1b5KIE357S5YoE9tcv6ro1/RAhyMEvZAerRji89fNuhbdjybaCV4ZZ2UETPAivRSJqqHocwpgJIT6VlUZ09S+uWDKAlBlTD9qsLforZOJ76atL6coR/8Sn6Q+gT4Obgr0VLMUFxCnALiid/T/XxgMczvj4KexZ0F6w8AaqCoX7/4QKeH3Y6ceWAdV97yWqppr4n2qiy15PA7fDzvy0udMnh4uc+NO4T0oyd0FgcjfNlJrk5fh3HW0TjiBTDgw/okKgfpAZoaOT46OldE81MF/ILixTLopA/0zxZZrlhNpi3s+Jtqk1106nJ47V5+KP1U8A7/WvHwpfvPQfqNPX8Tt01IQjXSP7f0JhXYbJVDNnc1xxIuB7CpoFq7RJAYW+tYrTbbPQUi9cO2QQldcgSEZaIdqhpV2afjL3ATnvC16R0e2klO0eSsLEdqNWnGIUGpfRDEeu8JvK4pJeECFwMWJrTr+a+BBNICj9sWCgaRxnLpfvubyE= jochem@the-bowlingbaan"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC6+Ow7SExlzcVRxbCuo/9CeDt4/4QvlRVN5UPdRimdKQjwH5tLgWWsP874uwt4MwvLdwDLCoPg2TpMBqm93hVMbOnj12eYGWVTRvJOZyrI6/RQQaTaLT8Eyf0Bg94eGZ5d+fdN5giVLhzm7hi4DV53frGpILABrylGppx+ZYqDlbPZ3qDpszk+jfPuLU9D3ODImWIqrNmvL7BeCk6ruusA2n35d0zARBHpSM/ks2//OfBtlMHXY4yEXDHFk8baVQOJ3SFn6VN/MKVV2UIU70uIYcGGudyBpQHH5tPwcfzE8Q2+jCxn+tCC9PY5i9TFaUTYPFdcPo42qdI4IrwxN2+V thijsg.dejong@gmail.com"
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD8JlFboq58p/a59aq3FENrlDI83DinAupG8OTlVkvR4tipETvNXNHmLrtYF13Lhf1xisp8ZSjlgoJeOXIWc2Abazb8/YG1Pr+YPncfwwaDn9C0Z/DrZ7XE+ecYbCXwj/HLu6KnlPdHj4GZMzQfx6ttQnllzxL8rBLDS85eQ+C9sYlmcN0zaNO5NrxWJx7Nm2YyhDWvEMPES4s8C4J+9/02ksVRRVGTXNPyWws1nz+48OoK5DvCV3Cq/PlAv6fMeg39z4y4xaXWRw6S0Qys825UJ40sWXdK9tasEUQTr+vpbIBsGD5VXg1ZPf7DfaxdrjOtkeHOqEOxv/F3fvh3Ku7B thijsg.dejong@gmail.com"
    ];
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.freedesktop.systemd1.manage-units") &&
        (action.lookup("unit") == "minecraft-server.service")  &&
        (subject.isInGroup("minecraft")))
        {
          return polkit.Result.YES;
        }
    });
  '';

  # Persist directories for the services fred runs
  environment.persistence."/persist".mounts = [
    "/var/lib/hydra"
    "/var/lib/acme"
    "/var/lib/libvirt"
  ];
  environment.etc."hydra/authorization/svthalia".source = "/persist/keys/github_token";

  services.postgresql.dataDir = "/persist/var/lib/postgresql/${config.services.postgresql.package.psqlSchema}";

  # nixpkgs.overlays =
  #   let
  #     modifyHydra = packagesNew: packagesOld: {
  #       hydra-unstable = packagesOld.hydra-unstable.overrideAttrs (
  #         old: {
  #           patches = (old.patches or []) ++ [
  #             # Remove warning about binary_cache_secret_key_file (copied from dhall-lang repo)
  #             (
  #               packagesNew.fetchpatch {
  #                 url = "https://github.com/NixOS/hydra/commit/df3262e96cb55bdfaac7726896728bfef675698b.patch";

  #                 sha256 = "1344cqlmx0ncgsh3dqn5igbxx6rgmlm14rgb5vi6rxkvwnfqy3zj";
  #               }
  #             )
  #           ];
  #         }
  #       );
  #     };

  #   in
  #     [ modifyHydra ];

  # environment.etc."hydra/concrexit.json".text = builtins.toJSON (import ./repo.nix "concrexit");
  # environment.etc."hydra/servers.json".text = builtins.toJSON (import ./repo.nix "servers");
  # environment.etc."hydra/concrexit_jobsets.nix".text = builtins.readFile ./concrexit_jobsets.nix;
  # environment.etc."hydra/servers_jobsets.nix".text = builtins.readFile ./servers_jobsets.nix;

  # environment.etc."hydra/machines".text = ''
  #   localhost x86_64-linux,builtin - 4 1 local,big-parallel,kvm,nixos-test
  # '';

  services.hydra-dev = {
    buildMachinesFiles = [ "/etc/hydra/machines" ];

    # enable = true;

    extraConfig = ''
      <githubstatus>
        authorization = svthalia
        jobs = concrexit:.*:.*-release
        inputs = src
        context = ci/hydra:concrexit
      </githubstatus>

      <githubstatus>
        authorization = svthalia
        jobs = servers:.*:.*-release
        context = ci/hydra:servers
      </githubstatus>

      <githubdeploys>
        authorization = svthalia
        jobs = servers:main:[^-]+
      </githubdeploys>

      enable_github_login = 1
      github_client_id = 50818437ab0434353b1e
      github_client_secret_file = "/persist/keys/github_client_secret"

      binary_cache_secret_key_file = ${nixServe.privateKey}
    '';

    hydraURL = "https://hydra.technicie.nl";
    useSubstitutes = true;

    listenHost = "127.0.0.1";

    notificationSender = "noreply@technicie.nl";
  };

  nix.gc.automatic = true;
  nix.gc.dates = "*:45";
  nix.gc.options = ''--max-freed "$((128 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | ${pkgs.gawk}/bin/awk '{ print $4 }')))"'';

  security.acme.email = "www@thalia.nu";
  security.acme.acceptTerms = true;

  services.nginx = {
    # enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    virtualHosts = {
      # "hydra.technicie.nl" = {
      #   enableACME = true;
      #   forceSSL = true;

      #   locations."/".proxyPass = "http://127.0.0.1:3000";
      # };
      # "cache.technicie.nl" = {
      #   enableACME = true;
      #   forceSSL = true;

      #   locations."/".proxyPass = "http://127.0.0.1:5000";
      # };
    };
  };

  # services.nix-serve = {
  #   enable = true;

  #   bindAddress = "127.0.0.1";

  #   secretKeyFile = nixServe.privateKey;
  # };

  # systemd.services.nix-serve-keys = {
  #   script = ''
  #     if [ ! -e ${nixServe.keyDirectory} ]; then
  #       mkdir -p ${nixServe.keyDirectory}
  #     fi
  #     if ! [ -e ${nixServe.privateKey} ] || ! [ -e ${nixServe.publicKey} ]; then
  #       ${pkgs.nix}/bin/nix-store --generate-binary-cache-key cache.technicie.nl ${nixServe.privateKey} ${nixServe.publicKey}
  #     fi
  #     chown -R nix-serve:hydra ${nixServe.keyDirectory}
  #     chmod 640 ${nixServe.privateKey}
  #   '';

  #   serviceConfig.Type = "oneshot";

  #   wantedBy = [ "multi-user.target" ];
  # };

  # Open web ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "20.09"; # Did you read the comment?

}
