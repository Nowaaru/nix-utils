{
  lib,
  git,
  stdenv,
  ripgrep,
  python311,
  python311Packages,
  onnxruntime,
  deepdanbooru,
  callPackage,
  cudaPackages,
  fetchFromGitHub,
  hydrus,
  hydrus-api-key ? "unset",
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "wd-e621-hydrus-tagger-environment";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "garbevoir";
    repo = "wd-e621-hydrus-tagger";
    rev = "b098b1aabf93bebca8e73d38c9343907310dab44";
    hash = "sha256-LpTGWhLV+F06D+jkpl7/IHBDLn8a9QRr0kNXu8YH8jo=";
  };

  buildPhase = ''
    # change all .bat files to .sh files
    export TMPDIR=$(mktemp -d);
    SED_RESULT=$(sed "s!git\+.*!${deepdanbooru.src}!" $src/requirements.txt);
    echo $SED_RESULT > $TMPDIR/requirements.txt

    echo "GRAAH"
    cat $TMPDIR/requirements.txt
    cp -r --no-preserve=mode --no-clobber $src/* $TMPDIR;


    for i in $(find $TMPDIR -maxdepth 1 -path "*.bat" -type f);
    do
      DIR_BASENAME=$(basename -s .bat $i);
      echo "basename: $DIR_BASENAME, in: $TMPDIR/$DIR_BASENAME.bat";

      ls -1 $TMPDIR
      if [[ $DIR_BASENAME = "start" ]]; then
        touch $TMPDIR/$DIR_BASENAME.sh;
        chmod a+rwx $TMPDIR/$DIR_BASENAME.sh;
        echo >> $TMPDIR/$DIR_BASENAME.sh << SCRUFFY
          cd $out;
          source ./venv/bin/activate;
          read -n 1;
    SCRUFFY
        rm $TMPDIR/start.bat;
      else
        sed -i "s/REPLACE_WITH_API_KEY/${hydrus-api-key}/" $i; #  $TMPDIR/$DIR_BASENAME.bat
        chmod a+rx $i;
        mv $i $TMPDIR/$DIR_BASENAME.sh
      fi
    done;

    cp -r $TMPDIR $out
    python3 -m venv $out/venv
  '';

  # configurePhase = ''
  # '';

  installPhase = ''
    source $out/venv/bin/activate
    cat $out/requirements.txt
    # pip install -r requirements.txt
  '';

  nativeBuildInputs = [
    cudaPackages.cudatoolkit
    cudaPackages.cuda_nvvp
    cudaPackages.cudnn_9_3
    onnxruntime
    ripgrep
  ];

  buildInputs = with python311Packages; [
    (python311.withPackages (python-pkgs:
      with python-pkgs; [
        certifi
        charset-normalizer
        click
        coloredlogs
        filelock
        flatbuffers
        humanfriendly
        hydrus-api
        idna
        imageio
        # modules ???
        mpmath
        networkx
        numpy
        opencv-python
        packaging
        pandas
        pillow
        protobuf
        python-dateutil
        pytz
        pywavelets
        pyyaml
        requests
        scikit-image
        scipy
        six
        sympy
        tifffile
        tqdm
        urllib3
      ]))
    deepdanbooru
    hydrus
    git
  ];


  meta = {
    description = "A bodged together edit of a WD1.4 tagging tool for Hydrus Network";
    homepage = "https://github.com/Garbevoir/wd-e621-hydrus-tagger";
    license = lib.licenses.gpl2;
    maintainers = with lib.maintainers; [];
  };
})
