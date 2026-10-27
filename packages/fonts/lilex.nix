{
  pkgs ? import <nixpkgs> { },
}:

pkgs.stdenv.mkDerivation {
  name = "lilex-font";
  src = pkgs.fetchzip {
    url = "https://github.com/mishamyrt/Lilex/releases/download/2.700/Lilex.zip";
    sha256 = "sha256-fiZi3b7YkBGmepu9ZZnVNROQ+u73wsXqQTV7u795vOA=";
    stripRoot = false;
  };

  installPhase = ''
    mkdir -p $out/share/fonts/truetype
    cp -r ttf/*.ttf $out/share/fonts/truetype/
  '';
}
