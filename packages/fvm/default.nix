{ pkgs, lib, ... }:
let
  inherit (pkgs)
    buildDartApplication
    fetchFromGitHub
    ;
  name = "fvm";
in
{
  flake.packages.${name} = buildDartApplication rec {
    pname = name;
    version = "2.4.1";

    src = fetchFromGitHub {
      owner = "leoafarias";
      repo = pname;
      rev = "v" + version;
      sha256 = "sha256-GFjd9+eI8Aa1HTG3SKtJuNz1JREnAG2p2T4TbcuDaIw=";
    };

    pubspecLock = lib.importJSON ./pubspec.lock.json;
  };
}
