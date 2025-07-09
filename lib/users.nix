toplevel @ {
  lib,
  self,
  ...
}: {
  mkUser = username: {
    programs ? [],
    sessionVariables,
    variables ? sessionVariables,
    extraSpecialArgs ? {},
    files ? {},
    flake ? null,
    modules ? [],
    system,
  }: {
    # TODO: omit this hacky  ass way and
    # use the home-mousersdules/systemic-home-manager
    # module to enable home.system = "x86_64-linux"
    __ = {inherit extraSpecialArgs flake system modules;};
    imports = programs;

    home = {
      username = lib.mkForce username;
      homeDirectory = lib.mkForce "/home/${username}";
      sessionVariables = lib.mkMerge [sessionVariables variables];
      stateVersion = lib.mkDefault "24.05";
      file = lib.mkDefault files;
    };

    programs.home-manager.enable = lib.mkForce true;
  };

  mkHomeManager = users: {
    ###
    # The directory in which to obtain system (generally, global)
    # programs from.
    ###
    sysProgramsRoot ? null,
    ###
    # Special arguments to be filled in automatically
    # to home modules.
    ###
    specialArgs ? {},
    ###
    # The name of the configuration directory
    # that will be used by the "configure"
    # special argument for both the systems
    # and the users.
    ###
    cfgRoot ? "cfg",
    ###
    # Where the files of the users are located.
    ###
    usrRoot,
    ###
    # The inputs of the flake creating this Home Manager
    # instance.
    ###
    inputs,
  }: {
    flake.homeConfigurations =
      lib.lists.foldl (
        a: raw_usr: let
          meta = (lib.gamindustri.systems.evalUserMetaFile "${usrRoot}/${usr.home.username.content}/meta.nix" {}).config;
          allInputAttributeNames = lib.attrsets.attrNames inputs;
          usr =
            raw_usr
            // {
              __ = lib.attrsets.mergeAttrsList [
                raw_usr.__
                {
                  flake = let
                    rawUsrName = usr.home.username.content;
                    closestMatchingFlakeId =
                      lib.lists.foldl'
                      (previousClosestMatch: currentFlakeString: let
                        nameDoesMatch = !(builtins.isNull (lib.strings.match ".*(${rawUsrName}).*" currentFlakeString));
                      in
                        if nameDoesMatch
                        then
                          (let
                            levenshteinDistancePrevious =
                              lib.strings.levenshtein rawUsrName previousClosestMatch;

                            levenshteinDistanceCurrent =
                              lib.strings.levenshtein rawUsrName currentFlakeString;
                          in
                            if (levenshteinDistancePrevious > levenshteinDistanceCurrent)
                            then currentFlakeString
                            else previousClosestMatch)
                        else (lib.traceVerbose "current match for '${currentFlakeString}' is null (query: ${rawUsrName})" previousClosestMatch))
                      (builtins.elemAt allInputAttributeNames 0)
                      allInputAttributeNames;
                  in
                    inputs.${lib.trace "closest matching flake id: ${closestMatchingFlakeId}" closestMatchingFlakeId};
                }
              ];
            };
        in (a
          // {
            ${usr.home.username.content} = lib.withSystem usr.__.system ({
                config,
                inputs',
                self',
                system,
                pkgs,
                ...
              } @ ctx:
                lib.homeManagerConfiguration (let
                  _configure = special_args: pre_program_name: let
                    program_name = lib.strings.replaceChars ["\\." "."] ["." "/"] pre_program_name;

                    mkCfgDir = cfgDir:
                      if builtins.pathExists cfgDir
                      then cfgDir
                      else
                        (
                          if (builtins.pathExists (cfgDir + ".nix"))
                          then cfgDir + ".nix"
                          else cfgDir
                        );
                    reqCfgDir = mkCfgDir "${usrRoot}/${usr.home.username.content}/${cfgRoot}/${program_name}";
                    fallbackCfgDir = mkCfgDir "${self}/cfg/${program_name}";
                    reqExists = builtins.pathExists reqCfgDir;
                    fallbackExists = builtins.pathExists fallbackCfgDir;
                  in
                    if reqExists && fallbackExists
                    then (lib.withInputs fallbackCfgDir special_args) // (lib.withInputs reqCfgDir special_args)
                    else
                      (
                        if reqExists
                        then (lib.withInputs reqCfgDir special_args)
                        else
                          (
                            if fallbackExists
                            then lib.withInputs fallbackCfgDir special_args
                            else abort "configuration '${program_name}' does not exist as '${reqCfgDir}[.nix]' or '${fallbackCfgDir}[.nix]'"
                          )
                      );

                  _extraSpecialArgs =
                    specialArgs
                    // rec {
                      inputs = usr.__.flake.inputs;
                    }
                    // usr.__.extraSpecialArgs;

                  programs-dir = sysProgramsRoot;

                  _pkgs =
                    if _extraSpecialArgs ? "pkgs"
                    then _extraSpecialArgs.pkgs
                    else self'.legacyPackages.default;
                in {
                  pkgs = builtins.trace _pkgs.config.permittedInsecurePackages _pkgs;
                  extraSpecialArgs =
                    _extraSpecialArgs
                    // rec {
                      # directory for user data (like meta.nix, cfg, programs...)
                      root = /${usrRoot}/${usr.home.username.content};
                      # function to read .nix files from designated cfg directory (else system fallback)
                      configure = _configure (
                        {
                          pkgs = _pkgs;
                          inherit (_pkgs) lib;
                          inherit configure;
                        }
                        // _extraSpecialArgs
                      );
                      programs = lib.throwIf ((builtins.isNull sysProgramsRoot) || !(builtins.pathExists sysProgramsRoot)) "attempt to index system programs when 'mkHomeManager.sysProgramsRoot' is not set (or does not exist)" lib.gamindustri.programs.mkProgramTreeFromDir programs-dir;
                      user = let
                        name = usr.home.username.content;
                        usr-programs-dir = /${usrRoot}/${name}/programs;
                      in {
                        inherit name;
                        programs =
                          if (builtins.pathExists usr-programs-dir)
                          then (lib.gamindustri.programs.mkProgramTreeFromDir usr-programs-dir)
                          else {};

                        # programs = import /${self}/programs (args
                        #   // specialArgs
                        #   // {
                        #     inherit (/* localFlake.lib.traceVal */ pkgs) config;
                        #     inherit (lib) withSystem;
                        #   });
                      };
                    };

                  modules = let
                    usernameContent = usr.home.username.content;
                  in [
                    # patches below
                    {
                      # patch to add application .desktop files
                      # automatically to launchers and things
                      xdg.systemDirs.data = ["/home/${usernameContent}/.local/state/nix/profiles/home-manager/home-path/share/applications/"];
                    }

                    # automatically setup wineprefix and other environment variables
                    {
                      home.sessionVariables = {
                        GAMES_DIR = lib.mkDefault "/home/${usernameContent}/Games";
                        WINEPREFIX = lib.mkDefault "/home/${usernameContent}/.wine";
                      };
                    }

                    (lib.attrsets.filterAttrs (k: _: !(builtins.elem k ["__"])) usr)
                    (lib.traceVal /${usrRoot}/${usernameContent})
                  ] ++ meta.home-modules;
                }));
          })
      ) {}
      users;
  };
}
