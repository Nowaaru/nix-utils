{
  inputs,
  flake,
  flake-parts-lib,
} @ lib: let
  inherit (flake-parts-lib) importApply;
in {
  evalSystemMetafile = metaFile: specialArgs: let
    newSpecialArgs =
      if specialArgs
      then specialArgs
      else {};
  in
    lib.evalModules {
      modules = [
        (importApply ./schema/system-meta.nix {
          inherit (lib.gamindustri.meta) mkIfElse;
          inherit (lib.options) mkOption mkEnableOption;
          inherit (lib) types mkIf mkMerge mkForce;
          inherit (inputs.flake-utils.lib) allSystems;
          systemImportArgs = newSpecialArgs;
        })

        (importApply metaFile newSpecialArgs)
      ];
    };

  evalUserMetaFile = metaFile: specialArgs: let
    newSpecialArgs =
      if specialArgs
      then specialArgs
      else {};
  in (lib.evalModules {
    modules = [
      (importApply ./schema/user-meta.nix {
        inherit lib inputs;
        inherit (inputs.flake-utils.lib) allSystems;
        inherit flake;

        userImportArgs = newSpecialArgs;
      })

      (importApply metaFile newSpecialArgs)
    ];
  });
}
