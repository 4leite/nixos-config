{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    chuwi-minibook-x.url = "github:4leite/nix-chuwi-minibook-x";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    nixosConfigurations.chewbacca = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./chewbacca.nix
	inputs.chuwi-minibook-x.nixosModules.default
        inputs.home-manager.nixosModules.default
      ];
    };
  };
}
