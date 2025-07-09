{
  self,
  attrsets,
  strings,
  inputs,
  lib,
  flake,
  ...
} @ lib-args: let
  specialLibraries = ["users.nix" "meta.nix"];
  metaFunctions = lib.callPackageWith lib ./meta.nix lib-args;
  metaLib = lib-args // metaFunctions;
in
  (attrsets.foldlAttrs (
      acc: k: _:
        acc
        // (let
          importPath = ./. + "/${k}";
        in {
          ${strings.removeSuffix ".nix" k} =
            if (builtins.elem k specialLibraries)
            then lib.callPackageWith lib importPath lib-args
            # metaLib.withInputs importPath (inputs
            #   // {
            #     lib = metaLib // {gamindustri = acc;};
            #   })
            else lib.callPackageWith lib importPath lib-args;
        })
    ) {} (
      attrsets.filterAttrs (
        k: v: v != "directory" && !(builtins.elem k ["default.nix"])
      ) (builtins.readDir ./.)
    ))
  // metaFunctions
