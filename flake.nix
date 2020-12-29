{
  description = "Thalia hardware servers NixOS configuration";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.hydra.url = "github:pingiun/hydra";
  inputs.nix-serve.url = "github:edolstra/nix-serve";

  outputs = { self, nixpkgs, hydra, nix-serve }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
      };

      # Derivation that trivially depends on the input source code revision.
      # As this is included in the "dhall-lang" aggregate, it forces every
      # commit to have a corresponding GitHub status check, even if the
      # commit doesn't make any changes (which can happen when merging
      # master in).
      rev = pkgs.runCommand "rev" {} ''echo "${self.rev}" > $out'';
    in
    {

    hydraJobs = rec {
      servers-release = pkgs.releaseTools.aggregate {
        name = "servers";

        constituents = [
          fred
          rev
        ];
      };

      fred = self.nixosConfigurations.fred.config.system.build.toplevel;
    };

    nixosConfigurations.fred = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        hydra.nixosModules.hydra
        ./fred.thalia.nu/configuration.nix
        ({ pkgs, ...}: {
          nixpkgs.overlays = [ nix-serve.overlay ];
          nix.registry.nixpkgs.flake = nixpkgs;
        })
      ];
    };

    nixosModules = {
      fredcache = ./modules/fredcache.nix;
      users = ./modules/users.nix;
      common = ./modules/common.nix;
    };

  };
}
