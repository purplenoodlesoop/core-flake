{ self
, flake-utils
, nixpkgs
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
      inheritShell = name: packages: mkShell {
        inherit name packages;
      };
      nonDefaultPkgs = builtins.removeAttrs shells [ "default" ];
      defaultShell.default = mkShell {
        inherit name;
        packages =
          let
            add = a: b: a ++ b;
            pkgs = builtins.attrValues nonDefaultPkgs;
            default = builtins.foldl' add shells.default pkgs;
          in
          tooling ++ default;
      };
      nonDefaultShells = lib.mapAttrs inheritShell nonDefaultPkgs;
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
