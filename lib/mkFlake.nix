{ self
, flake-utils
, nixpkgs
, fh
}: inputs @ { name, systemSpecific, ... }:
let
  lib = nixpkgs.lib;

  mkFlakePackages = packages:
    if builtins.hasAttr name packages
    then packages // { default = packages.${name}; }
    else packages;
  mkFlakeApp = name: app: {
    type = "app";
    program = "${app}/bin/${name}";
  };
  mkDevShells = { shells, tooling, mkShell }:
    let
      nonDefaultPkgs = builtins.removeAttrs shells [ "default" ];
      add = a: b: a ++ b;
      defaultShell.default = mkShell {
        inherit name;
        packages = tooling ++ (builtins.foldl' add shells.default (builtins.attrValues nonDefaultPkgs));
      };
      nonDefaultShells = lib.mapAttrs
        (name: packages: mkShell {
          inherit name packages;
        })
        nonDefaultPkgs;
    in
    defaultShell // nonDefaultShells;

  flake = system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      toolchains = import ./toolchains.nix {
        inherit lib self pkgs;
      };
      output = systemSpecific { inherit pkgs toolchains; };
    in
    {
      devShells = mkDevShells {
        inherit (pkgs) mkShell;
        shells = output.shells or { };
        tooling = with pkgs; [
          nil
          nixpkgs-fmt
          fh.packages.${system}.default
        ];
      };
      packages = mkFlakePackages (output.packages or { });
      apps = lib.mapAttrs mkFlakeApp (output.apps or { });
      checks = output.checks or { };
    };
  rest = builtins.removeAttrs inputs [ "name" "systemSpecific" ];
  flakeSet = flake-utils.lib.eachDefaultSystem flake;
in
lib.attrsets.recursiveUpdate flakeSet rest 
