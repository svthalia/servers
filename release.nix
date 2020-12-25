{ nixpkgs ? <nixpkgs>, system ? builtins.currentSystem }:
let
  pkgs = (import nixpkgs { inherit system; });

  fred = (pkgs.nixos ./fred.thalia.nu/configuration.nix).toplevel;

  # hail expects an activator script in `$out/bin/activate`. We let it
  # 1. add the configuration to /nix/var/nix/profiles/system
  # 2. run the switch-to-configuration script with systemd, because if
  #    hail is updated itself while switching, it would be killed during the switch
  activator = config: pkgs.writeScriptBin "activate" ''
      nix-env -p /nix/var/nix/profiles/system --set ${config}
      exec -a systemd-run ${pkgs.systemd}/bin/systemd-run \
        --description "Hail: Activate new configuration" \
        ${config}/bin/switch-to-configuration switch
    '';
in
{
  servers-release = pkgs.releaseTools.aggregate {
    name = "servers";

    constituents = [
      fred
    ];
  };

  activate-fred = activator fred;

  # This is to make sure we can do -A fred to only build that config in nix-build
  inherit fred;
}
