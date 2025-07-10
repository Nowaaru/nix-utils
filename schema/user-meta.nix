importParams @ {
  lib,
  flake,
  allSystems,
  location,
  ...
}: {config, ...}: {
  imports = [];

  options = with lib.options;
  with lib.types; {
    home-modules = mkOption {
      internal = true;
      readOnly = true;
      visible = false;
    };

    name = mkOption {
      description = "The name of this user.";
      type = uniq str;
      default = builtins.baseNameOf (lib.strings.normalizePath (lib.strings.removeSuffix "/meta.nix" (lib.strings.normalizePath location)));
      apply = v: (builtins.traceVerbose "chosen name: ${v}" v);
    };

    groups = mkOption rec {
      description = "The groups for this user.";
      type = listOf str;
      default = ["users"];
      apply = v: lib.lists.unique (v ++ default);
    };

    shell = mkOption {
      type = either str package;
      description = "The user's shell.";
      default = builtins.traceVerbose "packageset: ${config.packageset}" config.packageset.zsh;
      apply = v:
        if ((lib.strings.typeOf v) == "set")
        then v
        else config.packageset.${v};
    };

    description = mkOption {
      description = uniq "The description for this user.";
      type = nullOr str;
      default = "A Gamindustri user.";
    };

    packageset = mkOption {
      description = ''
        The packageset required for this user.
        This packageset must have the same architecture
        as the system it is being used by, otherwise assertions will fail.
      '';

      type =
        either
        (enum (lib.attrsets.foldlAttrs (acc: _: v: acc ++ (lib.attrsets.attrValues v)) [] flake.legacyPackages))
        (enum
          (lib.lists.foldl
            (acc: system:
              acc
              ++ (lib.lists.imap0 (idx: dep: "${system}.${dep}") (lib.attrNames flake.legacyPackages.${system})))
            [] (lib.attrNames flake.legacyPackages)));

      apply = value:
        if (lib.types.isType "set" value)
        then value
        else
          (
            let
              splitPackageSetId = lib.strings.split "\\." value;
            in
              flake.legacyPackages.${lib.lists.head splitPackageSetId}.${lib.lists.last splitPackageSetId}
          );

      default = "${config.system}.stable";
    };

    system = mkOption {
      description = ''
        The intended architecture for this user.
        If systems detect that their architecture is not in this list, assertions
        may fail.
      '';

      type = enum allSystems;
    };
  };

  config.home-modules = [
    {
      nixpkgs = {
        inherit (config.packageset) config;
      };
    }
  ];
}
