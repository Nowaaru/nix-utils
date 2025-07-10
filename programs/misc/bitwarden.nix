{
  lib,
  pkgs,
  withSystem,
  ...
} @ args:
withSystem "x86_64-linux" ({self', ...}: {
  home.packages = with pkgs; [
    bitwarden
  ];
})
