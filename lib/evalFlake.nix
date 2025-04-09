{
  nixpkgs,
  flake-utils,
}:
{
  # TODO: Return overlays as a part of a system-specific nixpkgs config returned by modules themselves
  overlays ? [ ],
  perSystem ? { },
  topLevel ? { },
  specialArgs ? { },
  config ? { },
}:
let
  inherit (nixpkgs)
    lib
    ;
  inherit (lib)
    mergeAttrs
    pipe
    ;
  flake.modules = [
    ./modules/flake.nix
    perSystem
  ];
  evalModules =
    args:
    pipe args [
      (mergeAttrs flake)
      lib.evalModules
      (m: m.config.flake)
    ];
  evalSystemSpecific =
    system:
    let
      pkgs = import nixpkgs {
        inherit system overlays config;
      };
      flake = evalModules {
        specialArgs = specialArgs // {
          inherit nixpkgs pkgs;
          core.compose = pkgs.callPackage ./compose.nix { };
        };
      };
    in
    flake.output;
in
(flake-utils.lib.eachDefaultSystem evalSystemSpecific) // topLevel
