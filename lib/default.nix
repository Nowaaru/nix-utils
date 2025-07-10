{
  attrsets,
  strings,
  flake,
  inputs,
  flake-parts-lib,
  self,
  lib,
  ...
} @ lib-args: let
  metaFunctions = import ./meta.nix (lib // lib-args);
  metaLib = lib-args // metaFunctions;
in
  (attrsets.foldlAttrs (
      acc: k: _:
        acc
        // (let
          importPath = ./. + "/${k}";
        in {
          ${strings.removeSuffix ".nix" k} = lib.callPackageWith lib importPath {
            lib = lib // metaLib // {gamindustri = acc;};
            gamindustri = acc;
            inherit flake inputs flake-parts-lib self;
          };
        })
    ) {} (
      attrsets.filterAttrs (
        k: v: v != "directory" && !(builtins.elem k ["default.nix"])
      ) (builtins.readDir ./.)
    ))
  // metaFunctions
