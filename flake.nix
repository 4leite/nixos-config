{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    chuwi-minibook-x.url = "github:4leite/nix-chuwi-minibook-x";

    home-manager = {
      # Match the release branch to your nixpkgs version
      url = "github:nix-community/home-manager/release-25.05";
      # Ensure home-manager uses your system's nixpkgs version
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs =
    {
      self,
      home-manager,
      nixpkgs,
      nixpkgs-unstable,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      specialArgs = inputs // {
        inherit system;
      };
      shared-modules = [
        home-manager.nixosModules.home-manager
        {
          home-manager = {
            useUserPackages = true;
            extraSpecialArgs = specialArgs;
          };
        }
      ];
    in
    {
      nixosConfigurations = {
        chewbacca = nixpkgs.lib.nixosSystem {
          specialArgs = specialArgs;
          system = system;
          modules = shared-modules ++ [
            inputs.chuwi-minibook-x.nixosModules.default
            ./shared/configuration.nix
            ./hosts/chewbacca/configuration.nix
            ./users/jon.nix
            ./users/coleite.nix
            ./users/bambam.nix
          ];
        };
        hotpie = nixpkgs.lib.nixosSystem {
          specialArgs = specialArgs;
          system = system;
          modules = shared-modules ++ [
            ./shared/configuration.nix
            ./hosts/hotpie/configuration.nix
            ./users/jon.nix
            inputs.vscode-server.nixosModules.default
          ];
        };
      };
    };
}
