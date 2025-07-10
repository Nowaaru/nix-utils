{pkgs, ...}: {
  home.packages = with pkgs; [
    dotnet-runtime_9
  ];

  home.sessionVariables = {
    DOTNET_ROOT = pkgs.dotnet-runtime_9 + /shared;
  };
}
