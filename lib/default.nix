lib: inputs: let
  specialLibraries = ["users.nix" "meta.nix"];
  metaFunctions = import ./meta.nix (inputs // {inherit lib;});
  metaLib = lib // metaFunctions;
in
  (lib.attrsets.foldlAttrs (
      acc: k: _:
        acc
        // (let
          importPath = ./. + "/${k}";
        in {
          ${lib.strings.removeSuffix ".nix" k} =
            if (builtins.elem k specialLibraries)
            then
              metaLib.withInputs importPath (inputs
                // {
                  lib = metaLib // {gamindustri = acc;};
                })
            else import importPath lib;
        })
    ) {} (
      lib.attrsets.filterAttrs (
        k: v: v != "directory" && !(builtins.elem k ["default.nix"])
      ) (builtins.readDir ./.)
    ))
  // metaFunctions
