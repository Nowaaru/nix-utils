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

    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = inputs @ {
    flake-parts,
    home-manager,
    nixpkgs-lib,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} (flake-params @ {
      config,
      withSystem,
      flake-parts-lib,
      ...
    }: let
      lib = nixpkgs-lib.outputs.lib.extend (prev: final: let
        overrides =
          {
            flake-parts = flake-parts-lib;
            maintainers = [];
            teams = [];
            inherit withSystem;
          }
          // home-manager.lib;
        gamindustri = prev.callPackageWith (final // overrides) ./lib {
          inherit inputs flake-parts-lib;
          flake = config.flake;
          self = ./.;
          lib = final // overrides;
        };
      in
        overrides // {inherit gamindustri;});
    in rec {
      imports = [
        inputs.home-manager.flakeModules.home-manager
      ];

      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      perSystem = {
        config,
        self',
        inputs',
        final,
        pkgs,
        system,
        ...
      } @ systemArguments: let
        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
            "dotnet-sdk-6.0.428"
            "dotnet-sdk-7.0.410"
            "dotnet-runtime-7.0.20"
          ];

          nvidia.acceptLicense = true;
        };
      in rec {
        _module.args.pkgs = legacyPackages.default;

        devShells.default = legacyPackages.default.mkShell {
          packages = [pkgs.nushell];
          shellHook = ''
            nu -li
          '';
        };

        # overlayAttrs = lib.foldlAttrs (acc: k: v: acc // { ${lib.strings.removeSuffix ".nix" k} = import builtins.readDir ./overlays);

        legacyPackages = let
          overlayLib = nixpkgs-item: let
            imported = import nixpkgs-item {inherit system config;};
          in
            imported.extend (s: p: {
              lib = imported.lib.extend (super: prev:
                (lib.removeAttrs lib ["teams" "maintainers"])
                // {
                  inherit (nixpkgs-item.lib) nixosSystem;
                  inherit (p.lib) teams maintainers;
                });
            });
        in {
          default = overlayLib inputs.nixpkgs;
          unstable = overlayLib inputs.nixpkgs;
          stable = overlayLib inputs.nixpkgs-mirror;
          master = overlayLib inputs.nixpkgs-master;

          nur = import inputs.nurpkgs {
            pkgs = self'.legacyPackages.default;
            nurpkgs = import inputs.nixpkgs {
              inherit (flake) overlays;
              inherit system config;
            };
          };
        };

        # Per-system attributes can be defined here. The self' and inputs'
        # module parameters provide easy access to attributes of the same
        # system.

        # Equivalent to  inputs'.nixpkgs.legacyPackages.hello;
      };

      flake = let
        overlays = let
          mkOverlay = outputFunction: _: prev: (withSystem prev.stdenv.hostPlatform.system outputFunction);
        in {
          # The usual flake attributes can be defined here, including system-
          # agnostic ones like nixosModule and system-enumerating ones, although
          # those are more easily expressed in perSystem.
          extend-lib = mkOverlay (overlayParams @ {config, ...}: {
            inherit lib;
          });

          node-neovim = mkOverlay (overlayParams @ {config, ...}: {
            nodePackages = config.legacyPackages.default.nodePackages // {neovim = config.packages.master.node-neovim-client;}; # config.legacyPackages.nodePackages // { neovim = final.neovim-node-client; };
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
      in {
        inherit overlays lib;
        homeManagerModules = {
          plasma = import ./home-modules/plasma;
        };
      };
    });
}
