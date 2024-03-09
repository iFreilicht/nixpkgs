{ lib
, stdenv
, qt5
, python3
, fetchFromGitHub
, aria
, ffmpeg
, libnotify
, pulseaudio
, sound-theme-freedesktop
}:

python3.pkgs.buildPythonApplication rec {
  pname = "persepolis";
  version = "4.0.0";

  src = fetchFromGitHub {
    owner = "persepolisdm";
    repo = "persepolis";
    rev = "refs/tags/${version}";
    hash = "sha256-2S6s/tWhI9RBFA26jkwxYTGeaok8S8zv/bY+Zr8TOak=";
  };

  patches = [
    # Upstream does currently not allow building from source on macOS. These patches can likely
    # be removed if https://github.com/persepolisdm/persepolis/issues/943 is fixed upstream
    ./0001-Allow-building-on-darwin.patch
    ./0002-Fix-startup-crash-on-darwin.patch
    ./0003-Search-PATH-for-aria2c-on-darwin.patch
    ./0004-Search-PATH-for-ffmpeg-on-darwin.patch
  ];

  postPatch = ''
    sed -i "s|'persepolis = persepolis.__main__'|'persepolis = persepolis.scripts.persepolis:main'|" setup.py

    # Automatically answer yes to all interactive questions during setup
    substituteInPlace setup.py --replace-fail "answer = input(" "answer = 'y'#"

    # Ensure dependencies with hard-coded FHS paths are properly detected
    substituteInPlace setup.py --replace-fail "isdir(notifications_path)" "isdir('${sound-theme-freedesktop}/share/sounds/freedesktop')"

    # Fix oversight in test script (can be removed once https://github.com/persepolisdm/persepolis/pull/942 is merged upstream)
    substituteInPlace setup.py --replace-fail "sys.exit('0')" "sys.exit(0)"
  '';

  postInstall = ''
    mkdir -p $out/share/applications
    cp $src/xdg/com.github.persepolisdm.persepolis.desktop $out/share/applications
  '';

  # prevent double wrapping
  dontWrapQtApps = true;
  nativeBuildInputs = [ qt5.wrapQtAppsHook ];

  # feed args to wrapPythonApp
  makeWrapperArgs = [
    "--prefix PATH : ${lib.makeBinPath [ aria ffmpeg libnotify ]}"
    "\${qtWrapperArgs[@]}"
  ];

  # The presence of these dependencies is checked during setuptoolsCheckPhase,
  # but apart from that, they're not required during build, only runtime
  nativeCheckInputs = [
    aria
    libnotify
    pulseaudio
    sound-theme-freedesktop
    ffmpeg
  ];

  propagatedBuildInputs = [
    pulseaudio
    sound-theme-freedesktop
  ] ++ (with python3.pkgs; [
    psutil
    pyqt5
    requests
    setproctitle
    setuptools
    yt-dlp
  ]);

  meta = with lib; {
    description = "A GUI for aria2";
    homepage = "https://persepolisdm.github.io/";
    license = licenses.gpl3Plus;
    mainProgram = "persepolis";
    maintainers = with maintainers; [ iFreilicht ];
  };
}
