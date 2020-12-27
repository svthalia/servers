{
  description = "Thalia hardware servers NixOS configuration";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";

  outputs = { self, nixpkgs }: {

    hydraJobs = {
      fred = self.nixosConfigurations.fred.config.system.build.toplevel;
    };

    nixosConfigurations.fred = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./fred.thalia.nu/configuration.nix
        ({ pkgs, ...}: {
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
