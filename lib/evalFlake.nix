{
  nixpkgs,
  flake-utils,
}:
{
  overlays ? [ ],
  module,
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
    module
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
        inherit system;
        inherit overlays;
      };
      flake = evalModules {
        specialArgs = {
          inherit nixpkgs pkgs;
          core.compose = pkgs.callPackage ./compose.nix { };
        };
      };
    in
    flake.output;
  topLevelConfig = evalModules {
    specialArgs = {
      inherit nixpkgs;
    };
  };
in
{
  inherit (topLevelConfig)
    templates
    overlays
    ;
}
// (flake-utils.lib.eachDefaultSystem evalSystemSpecific)
// topLevelConfig.extraConfig
