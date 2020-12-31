# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

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
  # this is required until nix 2.4 is released
  nix.package = pkgs.nixUnstable;

  environment.systemPackages = with pkgs; [
      git
    ];

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

  # Persist directories for the services fred runs
  environment.persistence."/persist".links = [
    "/var/lib/acme"
  ];
  environment.persistence."/persist".mounts = [
    "/var/lib/hydra"
  ];
  environment.etc."hydra/authorization/svthalia".source = "/persist/keys/github_token";

  services.postgresql.dataDir = "/persist/var/lib/postgresql/${config.services.postgresql.package.psqlSchema}";

  nixpkgs.overlays =
    let
      modifyHydra = packagesNew: packagesOld: {
        hydra-unstable = packagesOld.hydra-unstable.overrideAttrs (
          old: {
            patches = (old.patches or []) ++ [
              # Remove warning about binary_cache_secret_key_file (copied from dhall-lang repo)
              (
                packagesNew.fetchpatch {
                  url = "https://github.com/NixOS/hydra/commit/df3262e96cb55bdfaac7726896728bfef675698b.patch";

                  sha256 = "1344cqlmx0ncgsh3dqn5igbxx6rgmlm14rgb5vi6rxkvwnfqy3zj";
                }
              )
            ];
          }
        );
      };

    in
      [ modifyHydra ];

  environment.etc."hydra/concrexit.json".text = builtins.toJSON (import ./repo.nix "concrexit");
  environment.etc."hydra/servers.json".text = builtins.toJSON (import ./repo.nix "servers");
  environment.etc."hydra/concrexit_jobsets.nix".text = builtins.readFile ./concrexit_jobsets.nix;
  environment.etc."hydra/servers_jobsets.nix".text = builtins.readFile ./servers_jobsets.nix;

  environment.etc."hydra/machines".text = ''
    localhost x86_64-linux,builtin - 4 1 local,big-parallel,kvm,nixos-test
  '';

  services.hydra-dev = {
    buildMachinesFiles = [ "/etc/hydra/machines" ];

    enable = true;

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
        jobs = servers:main:[^-]
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
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedTlsSettings = true;
    recommendedProxySettings = true;
    virtualHosts = {
      "hydra.technicie.nl" = {
        enableACME = true;
        forceSSL = true;

        locations."/".proxyPass = "http://127.0.0.1:3000";
      };
      "cache.technicie.nl" = {
        enableACME = true;
        forceSSL = true;

        locations."/".proxyPass = "http://127.0.0.1:5000";
      };
    };
  };

  services.nix-serve = {
    enable = true;

    bindAddress = "127.0.0.1";

    secretKeyFile = nixServe.privateKey;
  };

  systemd.services.nix-serve-keys = {
    script = ''
      if [ ! -e ${nixServe.keyDirectory} ]; then
        mkdir -p ${nixServe.keyDirectory}
      fi
      if ! [ -e ${nixServe.privateKey} ] || ! [ -e ${nixServe.publicKey} ]; then
        ${pkgs.nix}/bin/nix-store --generate-binary-cache-key cache.technicie.nl ${nixServe.privateKey} ${nixServe.publicKey}
      fi
      chown -R nix-serve:hydra ${nixServe.keyDirectory}
      chmod 640 ${nixServe.privateKey}
    '';

    serviceConfig.Type = "oneshot";

    wantedBy = [ "multi-user.target" ];
  };

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
