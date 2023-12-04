{ pkgs ? import <nixpkgs> { }
}:
import ./default.nix {
  inherit (pkgs) buildDartApplication fetchFromGitHub lib;
}
