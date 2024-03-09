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
, pkg-config
, meson
, ninja
}:

python3.pkgs.buildPythonApplication rec {
  pname = "persepolis";
  version = "4.0.0";
  format = "other";

  src = fetchFromGitHub {
    owner = "persepolisdm";
    repo = "persepolis";
    rev = "0cd869bfa82a002ae7460806171c2a89d4cf65cc";
    hash = "sha256-Sitfci0Qop1FnnzSkUEF0d9zMJlnmE4gDD44ZWWu3Fw=";
  };

  patches = [
    # Upstream does currently not allow building from source on macOS. These patches can likely
    # be removed if https://github.com/persepolisdm/persepolis/issues/943 is fixed upstream
    ./0002-Fix-startup-crash-on-darwin.patch
    ./0003-Search-PATH-for-aria2c-on-darwin.patch
    ./0004-Search-PATH-for-ffmpeg-on-darwin.patch
  ];

  postPatch = ''
    # Ensure dependencies with hard-coded FHS dependencies are properly detected
    substituteInPlace check_dependencies.py --replace-fail "isdir(notifications_path)" "isdir('${sound-theme-freedesktop}/share/sounds/freedesktop')"
  '';

  postInstall = ''
    mkdir -p $out/share/applications
    cp $src/xdg/com.github.persepolisdm.persepolis.desktop $out/share/applications
  '';

  # prevent double wrapping
  dontWrapQtApps = true;
  nativeBuildInputs = [ meson ninja pkg-config qt5.wrapQtAppsHook ];

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
