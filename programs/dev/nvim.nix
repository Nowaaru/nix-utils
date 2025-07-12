{
  inputs,
  configure,
  config,
  pkgs,
  ...
}: {
  imports = [inputs.nvf.homeManagerModules.default];

  programs.nvf = {
    enable = true;
    settings.vim = configure "nvf" config;
  };
}
