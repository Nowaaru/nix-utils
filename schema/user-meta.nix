importParams@{ 
    lib,
    inputs,
    allSystems,
}: {config, ...} @ moduleParams: {
    imports = [];

    options = with lib.options; with lib.types; {
      description = mkOption {
        description = "The description for this system.";
        type = nullOr str;
        default = "A NixOS system.";
      };

      packageset = mkOption {
        description = ''
            The packageset required for this system. 
            This packageset must have the same architecture
            as the system it is being used by, otherwise assertions will fail.
        '';

        type = either 
                (oneOf 
                    (enum lib.attrsets.foldlAttrs 
                        (acc: k: v: 
                            acc ++ (lib.attrsets.attrValues v)) [] inputs.gamindustri-utils.legacyPackages)
                (enum 
                    lib.lists.foldl 
                        (acc: system: 
                            acc ++ (lib.lists.imap0 
                                (idx: dep: "${system}.${dep}") (lib.attrNames inputs.gamindustri-utils.legacyPackages.${v}))) 
                        [] config.systems));
        
        apply = (value: 
            if ((lib.typeOf value) == "set")
            then value
            else (
                let 
                    splitPackageSetId = lib.strings.split "\\." value;
                in 
                    inputs.gamindustri-utils.legacyPackages.${lib.lists.head splitPackageSetId}.${lib.lists.tail splitPackageSetId}));
      };

      systems = mkOption {
        description = ''
            The intended architecture for this user.
            If systems detect that their architecture is not in this list, assertions
            may fail.
        '';

        type = enum allSystems; 
      };
    };
}
