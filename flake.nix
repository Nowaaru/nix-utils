{
  description = "Noire's flake utilities.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    dependency-utils = {
      inherit (home-manager.lib.hm) dag;
    };
  in
    nixpkgs.lib.extend
    (self: _: {
      noire = import ./. (self // dependency-utils);
    });
}
