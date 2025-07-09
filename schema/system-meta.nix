lib @ {
  mkIf,
  mkMerge,
  mkEnableOption,
  mkOption,
  allSystems,
  systemImportArgs,
  ...
}: baseModule @ {config, ...}: {
  options = with lib.types; {
    system = mkOption {
      type = submodule (systemModule @ {config, ...}: {
        imports = [];

        options = {
          file = mkOption {
            description = "The path to the system's 'default.nix' file.";
            type = path;
          };

          description = mkOption {
            description = "The description for this system.";
            type = nullOr str;
            default = "A NixOS system.";
          };

          architecture = mkOption {
            description = "The system architecture that this configuration should be run on.";
            type = enum allSystems;
          };

          specialArgs = mkOption {
            description = "Arguments to be layed over all modules.";
            type = attrs;
            default = {};
          };

          usersDir = mkOption {
            description = "The directory for the currently-registered system users.";
            type = nullOr path;
          };

          baseModules = mkOption {
            description = "Intrinsic modules to the system configuration.";
            type = listOf (oneOf [(functionTo attrs) attrs]); # TODO: fix this module type
          };
        };

        config.baseModules = [
          {nixpkgs.pkgs = lib.mkForce baseModule.config.repositories.main;}
          {nixpkgs.hostPlatform = lib.mkForce baseModule.config.system.architecture;}
        ];

        config.specialArgs =
          lib.mkMerge
          [
            {meta = baseModule.config;}
            baseModule.config.repositories.fallback
            systemImportArgs
          ];
      });
    };

    packages = mkOption {
      type = submodule (packageModule @ {config, ...}: {
        readonly = mkOption {
          type = submodule (readonlyModule @ {config, ...}: {
            options.enable = mkEnableOption "readonly packages for this system.";

            config = mkIf readonlyModule.config.enable {
              system.baseModules = [
                ({}: {
                  imports = [
                    inputs.gamindustri-utils.inputs.nixpkgs.nixosModules.readOnlyPkgs
                  ];
                })
              ];
            };
          });
        };
      });
    };

    repositories = {
      main = mkOption {
        description = "Primary repositiory of utilities and packages to be added to as 'pkgs'";
        type = lib.types.pkgs;
      };

      fallback = mkOption {
        description = "Fallback repositories of utilities and packages to be added to 'specialArgs'";
        type = attrsOf lib.types.pkgs;
        default = {};
      };
    };
  };

  config = {};
}
