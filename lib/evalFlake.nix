{
  nixpkgs,
  flake-utils,
}:
let
  # nixpkgs 26.11 removed x86_64-darwin, and importing it aborts evaluation
  # rather than yielding an empty package set. Left in the list it takes down
  # `nix flake show` and `nix flake check` for every consumer of this library.
  systems = nixpkgs.lib.subtractLists [ "x86_64-darwin" ] flake-utils.lib.defaultSystems;
in
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
(flake-utils.lib.eachSystem systems evalSystemSpecific) // topLevel
