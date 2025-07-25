{
  stdenv,
  fetchgit,
  lib,
  libdrm,
  libcap,
  libglvnd,
  libpulseaudio,
  libGL,
  egl-wayland,
  wayland-scanner,
  wayland,
  meson,
  cmake,
  ninja,
  pkg-config,
  libX11,
  libXcomposite,
  libXrandr,
  libXrender,
  libXext,
  libXcursor,
  libXfixes,
  libXi,
  addDriverRunpath,
  wrapperDir ? "/run/wrappers/bin",
  ...
}:
with stdenv;
  mkDerivation (finalAttrs: rec {
    pname = "gpu-screen-recorder-ui";
    version = "1.1.7";

    outputs = ["build" "out"];
    phases = ["setupPhase" "configurePhase" "buildPhase" "fixupPhase"];

    src = fetchgit {
      name = "gsr-ui";
      url = "https://repo.dec05eba.com/gpu-screen-recorder-ui";
      rev = "8003c209fea16cd164817306cb33d46ac61a44f0";
      hash = "sha256-qDehZ4Csj79kyGOZwbI6LUu2OlC3032tZ7Vr662knpg=";
    };

    nativeBuildInputs = [
      pkg-config
      cmake # needed (i think?)
      meson # paired with ninja
      ninja # paired with meson
    ];

    buildInputs = [
      libX11
      libXrandr
      libXrender
      libXcursor
      libXcomposite
      libXfixes
      libXext
      libXi

      wayland
      egl-wayland
      wayland-scanner

      libcap

      libpulseaudio
      libglvnd
      libdrm
    ];

    configurePhase = ''
      meson configure --prefix=$out --buildtype=release -Dstrip=true $build
    '';

    setupPhase = ''
      cd $src
      meson setup $build $src
    '';

    buildPhase = ''
      ninja -C $build install
    '';

    postInstall = let
      libraryPath = "${
        lib.makeLibraryPath ([
            libGL
            addDriverRunpath.driverLink
          ]
          ++ buildInputs)
      }";
    in ''
      mkdir -p $out/bin/.wrapped
      mv $out/bin/gsr-ui $out/bin/.wrapped/
      makeWrapper "$out/bin/.wrapped/gsr-ui" "$out/bin/gsr-ui" \
        --prefix LD_LIBRARY_PATH : "${libraryPath}" \
        --prefix PATH : "${wrapperDir}" \
        --prefix PATH : "${libraryPath}" \
        --suffix PATH : "$out/bin"
    '';

    meta = {
      description = "dec05eba";
      homepage = "https://dec05eba.com";
      license = lib.licenses.gpl3;

      maintainers = with lib.maintainers; [""];
    };
  })
