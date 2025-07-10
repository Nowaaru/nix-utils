{
  inputs,
  flake,
  flake-parts-lib,
  lib,
  self,
  ...
}: let
  inherit (flake-parts-lib) importApply;
in {
  evalSystemMetafile = metaFile: specialArgs: let
    newSpecialArgs =
      if (!(builtins.isNull specialArgs))
      then specialArgs
      else {};
  in
    lib.evalModules {
      modules = [
        (importApply (self + /schema/system-meta.nix) {
          inherit (lib.gamindustri.meta) mkIfElse;
          inherit (lib.options) mkOption mkEnableOption;
          inherit (lib) types mkIf mkMerge mkDefault mkForce;
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

    checkedMetaFile =
      if (lib.types.isType "lambda" (import metaFile))
      then importApply metaFile newSpecialArgs
      else metaFile;
  in (lib.evalModules {
    modules = [
      (importApply (self + /schema/user-meta.nix) {
        inherit (inputs.flake-utils.lib) allSystems;
        inherit flake;
        inherit lib;
        location = metaFile;
      })

      checkedMetaFile
    ];
  });
}
