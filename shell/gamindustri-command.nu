#!/usr/bin/env nu

# the Gamindustri utility command set.
#
# Use for maintenance upon several
# gamindustri flakes.
def "gamindustri" [ ] {
    gamindustri help
}

# display the help message for this command
def "gamindustri help" [] {
    let subcommandNames = [ "update" ];
    gamindustri --help
}


# update gamindustri
def "gamindustri update" [
    --user (-u): string # The username to update.
] {
    let base_path = if ("GAMINDUSTRI" in $env) {
        $env.GAMINDUSTRI
    } else { "/etc/nixos" };

    let gamindustri_roots = [ "gamindustri" "gamindustri-residents" "gamindustri-utils" ];
    let userUpgrade = if ($user != null) {
        $"gamindustri-residents/user-($user)"
    } else { "" };

    nix flake update --flake $"($base_path)" gamindustri gamindustri-utils gamindustri-residents ($userUpgrade);
}
