{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote.url = "github:nix-community/lanzaboote/v1.1.0";
    lanzaboote.inputs.nixpkgs.follows = "nixpkgs";
    nix-firefox-addons.url = "github:osipog/nix-firefox-addons";
    nix-firefox-addons.inputs.nixpkgs.follows = "nixpkgs";

    # Inspiration from https://simonshine.dk/articles/managing-secrets-privately-with-sops-nix
    nixos-secrets.url = "git+file:./secrets";
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      meta = import ./meta.nix { inherit (nixpkgs) lib; };

      cfg =
        system: mainModule:
        nixpkgs.lib.nixosSystem {
          system = system;

          specialArgs = {
            inherit inputs meta;
          };

          modules = [
            {
              nixpkgs.overlays = import ./overlays;
            }
            mainModule
          ];
        };
    in
    {
      nixosConfigurations = {
        lambda = cfg "aarch64-linux" ./hosts/lambda;
        mu = cfg "x86_64-linux" ./hosts/mu;
        phi = cfg "x86_64-linux" ./hosts/phi;
        tau = cfg "x86_64-linux" ./hosts/tau;
      };
    };
}
