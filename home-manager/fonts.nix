{ config, pkgs, ... }:

{

  fonts.fontconfig.enable = true;

  home.packages = [
    (import ../packages/fonts/lilex.nix { inherit pkgs; })
    pkgs.fragment-mono
  ];

}
