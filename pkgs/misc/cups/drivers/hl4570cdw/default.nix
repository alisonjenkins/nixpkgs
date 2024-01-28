{ lib, stdenv, fetchurl, cups, dpkg, gnused, makeWrapper, ghostscript, file, a2ps, coreutils, gawk }:

let
  version = "1.1.1-5";
  cupsdeb = fetchurl {
    url = "https://download.brother.com/welcome/dlf005946/hl4570cdwcupswrapper-${version}.i386.deb";
    sha256 = "sha256-1RraaVbVr3datoYWOioozU9SmQyCnVj1PpXyYtOjWQw=";
  };
  srcdir = "hl4570cdwcupswrapper-src-${version}";
  cupssrc = fetchurl {
    url = "https://download.brother.com/welcome/dlf006746/${srcdir}.tar.gz";
    sha256 = "sha256-IbORwi75Gnh3Y4/2V8F4IiWLRGmYkls0fVStnnMtLVQ=";
  };
  lprdeb = fetchurl {
    url = "https://download.brother.com/welcome/dlf005944/hl4570cdwlpr-${version}.i386.deb";
    sha256 = "sha256-cZ1JLI7/FvyqKN+ahxOtlAAzkYmO59rw8D3QGB+6g9Y=";
  };

  brhlFilterPath = "/usr/local/Brother/Printer/hl4570cdw/lpd/brhl4570cdwfilter";
  brprintconfPath = "/usr/bin/brprintconf_hl4570cdw";
  cupswrapperPath = "/usr/local/Brother/Printer/hl4570cdw/cupswrapper/";
  filterPath = "/usr/local/Brother/Printer/hl4570cdw/lpd/filterhl4570cdw";
  psconvertij2Path = "/usr/local/Brother/Printer/hl4570cdw/lpd/psconvertij2";
  setupPrintcapijPath = "/usr/local/Brother/Printer/hl4570cdw/inf/setupPrintcapij";
  filterBasename = baseNameOf filterPath;
in
stdenv.mkDerivation {
  pname = "cups-brother-hl4570cdw";
  inherit version;
  nativeBuildInputs = [ makeWrapper dpkg ];
  buildInputs = [ cups ghostscript a2ps ];

  unpackPhase = ''
    tar -xvf ${cupssrc}
  '';

  buildPhase = ''
    gcc -Wall ${srcdir}/brcupsconfig/brcupsconfig.c -o brcupsconfpt1
  '';

  installPhase = ''
     # install lpr
     dpkg-deb -x ${lprdeb} $out

     substituteInPlace $out${filterPath} \
       --replace-fail /usr "$out/usr"
     substituteInPlace $out${setupPrintcapijPath} \
       --replace-fail /usr "$out/usr"

     sed -i '/GHOST_SCRIPT=/c\GHOST_SCRIPT=gs' $out${psconvertij2Path}

     patchelf --set-interpreter ${stdenv.cc.libc}/lib/ld-linux.so.2 $out${brhlFilterPath}
     patchelf --set-interpreter ${stdenv.cc.libc}/lib/ld-linux.so.2 $out${brprintconfPath}

     wrapProgram $out${psconvertij2Path} \
      --prefix PATH ":" ${ lib.makeBinPath [ gnused coreutils gawk ] }

     wrapProgram $out${filterPath} \
      --prefix PATH ":" ${ lib.makeBinPath [ ghostscript a2ps file gnused coreutils ] }


     dpkg-deb -x ${cupsdeb} $out

     # substituteInPlace $out/opt/brother/Printers/hl4570cdw/cupswrapper/cupswrapperhl4570cdw \
     #  --replace-fail /opt "$out/opt"

     mkdir -p $out/lib/cups/filter
     ln -s $out/${filterPath} $out/lib/cups/filter/${filterBasename}

    # ln -s $out/opt/brother/Printers/hl4570cdw/cupswrapper/brother_hl4570cdw_printer_en.ppd $out/lib/cups/filter/brother_hl4570cdw_printer_en.ppd

    # cp brcupsconfpt1 $out/opt/brother/Printers/hl4570cdw/cupswrapper/
    # ln -s $out/opt/brother/Printers/hl4570cdw/cupswrapper/brcupsconfpt1 $out/lib/cups/filter/brcupsconfpt1
    # ln -s $out/usr/local/Brother/Printer/hl4570cdw/lpd/filterhl4570cdw $out/lib/cups/filter/brother_lpdwrapper_hl4570cdw

    # wrapProgram $out/opt/brother/Printers/hl4570cdw/cupswrapper/cupswrapperhl4570cdw \
      # --prefix PATH ":" ${ lib.makeBinPath [ gnused coreutils gawk ] }
  '';

  meta = {
    homepage = "http://www.brother.com/";
    description = "Brother hl4570cdw printer driver";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
    downloadPage = "https://support.brother.com/g/b/downloadlist.aspx?c=gb&lang=en&prod=hl4570cdw_all&os=128";
  };
}
