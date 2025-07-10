{
  withSystem,
  pkgs,
  ...
}:
withSystem "x86_64-linux" ({self', ...}: {
  home.packages = with pkgs; [
    vesktop
    arrpc
  ];
})
