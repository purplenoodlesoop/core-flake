{ pkgs, ... }:
{
  flake.perSystem.packages.fvm = pkgs.callPackage ./package.nix { };
}
