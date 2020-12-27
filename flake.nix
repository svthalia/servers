{
  description = "Thalia hardware servers NixOS configuration";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-20.09";

  outputs = { self, nixpkgs }: {

    nixosConfigurations.fred = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./fred.thalia.nu/configuration.nix
        ({ pkgs, ...}: {
          nix.registry.nixpkgs.flake = nixpkgs;
        })
      ];
    };

  };
}
