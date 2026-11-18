{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
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
    nix-firefox-addons.inputs.flake-utils.follows = "flake-utils";
    acer-charger-mute.url = "github:goll72/acer-charger-mute";
    acer-charger-mute.inputs.nixpkgs.follows = "nixpkgs";
    zellij-prune.url = "github:goll72/zellij-prune";
    zellij-prune.inputs.nixpkgs.follows = "nixpkgs";
    zellij-prune.inputs.flake-utils.follows = "flake-utils";

    # Inspiration from https://simonshine.dk/articles/managing-secrets-privately-with-sops-nix
    nixos-secrets.url = "git+file:./secrets";
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      meta = import ./meta.nix {
        inherit (nixpkgs) lib;
      };

      lib' = import ./lib {
        inherit (nixpkgs) lib;
        inherit meta;
      };

      cfg =
        system: mainModule:
        nixpkgs.lib.nixosSystem {
          inherit system;

          specialArgs = {
            inherit inputs meta lib';
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
