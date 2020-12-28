{
  description = "Thalia hardware servers NixOS configuration";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";
  inputs.hydra.url = "github:pingiun/hydra";
  inputs.nix-serve.url = "github:edolstra/nix-serve";

  outputs = { self, nixpkgs, hydra, nix-serve }: {

    hydraJobs = {
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
