{
  flake-parts-lib,
  attrsets,
  strings,
  inputs,
} @ lib-args: let
  specialLibraries = ["users.nix" "meta.nix"];
  metaFunctions = import ./meta.nix lib-args;
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
            then
              metaLib.withInputs importPath (inputs
                // {
                  lib = metaLib // {gamindustri = acc;};
                })
            else import importPath lib-args;
        })
    ) {} (
      attrsets.filterAttrs (
        k: v: v != "directory" && !(builtins.elem k ["default.nix"])
      ) (builtins.readDir ./.)
    ))
  // metaFunctions
