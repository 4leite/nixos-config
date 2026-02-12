{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    chuwi-minibook-x.url = "github:4leite/nix-chuwi-minibook-x";

    home-manager = {
      url = "github:nix-community/home-manager";
    };
  };

  outputs =
    {
      self,
      home-manager,
      nixpkgs,
      nixpkgs-master,
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
            {
              nixpkgs.overlays = [
                (final: prev: {
                  vscode = (import nixpkgs-master {
                    system = prev.system;
                    config.allowUnfree = true;
                  }).vscode;
                })
              ];
            }
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
          ];
        };
      };
    };
}
