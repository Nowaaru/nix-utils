{
  description = "Description for the project";

  inputs = {
    nixpkgs-master.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-mirror.url = "github:nixos/nixpkgs/release-25.05";
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nurpkgs.url = "github:nix-community/NUR";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-utils.url = "github:numtide/flake-utils";

    nixgl.url = "github:nix-community/nixGL";
    lanzaboote.url = "github:nix-community/lanzaboote";
  };

  outputs = inputs @ {
    flake-parts,
    nixpkgs-lib,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} (flake-params @ {
      withSystem,
      flake-parts-lib,
      ...
    }: let
      lib = nixpkgs-lib.outputs.lib.extend (_: _: {
        flake-parts = flake-parts-lib;
        gamindustri = {
          mkFlake = flake-parts.lib.mkFlake {inherit inputs;};
        };
      });
    in {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        config,
        self',
        inputs',
        final,
        pkgs,
        system,
        ...
      }: let
        overlays = import ./overlays withSystem (inputs
          // {
            inherit (default) lib;
          });

        default = import inputs.nixpkgs {
          inherit system overlays config;
        };
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "dotnet-sdk-6.0.428"
            "dotnet-sdk-7.0.410"
            "dotnet-runtime-7.0.20"
          ];
        };
      in rec {
        _module.args.pkgs = legacyPackages.default;

        # overlayAttrs = lib.foldlAttrs (acc: k: v: acc // { ${lib.strings.removeSuffix ".nix" k} = import builtins.readDir ./overlays);

        legacyPackages = {
          inherit default;
          ligmaballs = self';

          stable = import inputs.nixpkgs-mirror {
            inherit system overlays config;
          };

          master = import inputs.nixpkgs-master {
            inherit system overlays config;
          };

          nur = import inputs.nurpkgs {
            pkgs = self'.legacyPackages.default;
            nurpkgs = import inputs.nixpkgs {
              inherit system config;
            };
          };
        };

        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
      };

      flake.lib = lib;
      flake.overlays = let
        mkOverlay = outputFunction: _: prev: (withSystem prev.stdenv.hostPlatform.system outputFunction);
      in {
        # The usual flake attributes can be defined here, including system-
        # agnostic ones like nixosModule and system-enumerating ones, although
        # those are more easily expressed in perSystem.
        extend-lib = mkOverlay (overlayParams @ {config, ...}: {
          inherit lib;
        });

        node-neovim = mkOverlay (overlayParams @ {config, ...}: {
          nodePackages = config.legacyPackages.nodePackages // {neovim = config.packages.master.node-neovim-client;}; # config.legacyPackages.nodePackages // { neovim = final.neovim-node-client; };
        });

        stable-basedpyright = mkOverlay (overlayParams @ {config, ...}: {
          inherit
            (config.legacyPackages.stable)
            basedpyright
            lldb
            ;
        });

        wine-update-10-2 = let
          version = "10.2";
        in
          mkOverlay (overlayParams @ {config, ...}: {
            wineWowPackages.full = config.legacyPackages.wineWowPackages.full.overrideAttrs (a:
              a
              // {
                inherit version;
                src = builtins.fetchurl {
                  url = "https://dl.winehq.org/wine/source/10.x/wine-${version}.tar.xz"; #
                  sha256 = "sha256:0gr40jnv4wz23cgvk21axb9k0irbf5kh17vqnjki1f0hryvdz44x";
                };
              });
          });
      };
    });
}
