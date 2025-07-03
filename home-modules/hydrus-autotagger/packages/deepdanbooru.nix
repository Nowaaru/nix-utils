{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools-scm,
  setuptools,
  click,
  numpy,
  scikit-image,
  tensorflowWithCuda,
  requests,
  six,
  ...
}:
buildPythonPackage {
  pname = "DeepDanbooru";
  version = "";

  #  outputs = ["bin" "out"];

  src = fetchFromGitHub {
    owner = "KichangKim";
    repo = "DeepDanbooru";
    rev = "98d9315ab702e177de706825f9cee981c9afb928";
    hash = "sha256-W/OWl2WDmTko/WuOtLPCBUT7YHc3YftTVKUysAvXcvQ=";
  };

  build-system = [
    # setuptools-scm
    setuptools
  ];

  dependencies = [
    click
    numpy
    scikit-image
    tensorflowWithCuda
    requests
    six
  ];

  # installPhase =  ''
  #   echo $out
  #   echo $src
  # '';

  configurePhase = ''
    # cp -r $src $out
    # mkdir $out/bin
    # ls $out
    # ls $src
    return 0;
  '';

  meta = {
    description = "AI based multi-label girl image classification system, implemented by using TensorFlow.";
    homepage = "https://github.com/KichangKim/DeepDanbooru";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
  };
}

/*
{
  lib,
  stdenv,
  fetchFromGitHub,
  python311,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "DeepDanbooru";
  version = "v3";

  src = fetchFromGitHub {
    owner = "KichangKim";
    repo = "DeepDanbooru";
    rev = "98d9315ab702e177de706825f9cee981c9afb928";
    hash = "sha256-LpTGWhLV+F06D+jkpl7/IHBDLn8a9QRr0kNXu8YH8jo=";
  };

  nativeBuildInputs = [
  ];

  buildInputs = [
    (python311.withPackages (python-pkgs:
      with python-pkgs; [
        setuptools-scm
        setuptools
        click
        numpy
        scikit-image
        tensorflowWithCuda
        requests
        six
      ]))
  ];

  meta = {
    description = "AI based multi-label girl image classification system, implemented by using TensorFlow.";
    homepage = "https://github.com/KichangKim/DeepDanbooru";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [];
  };
})
*/
