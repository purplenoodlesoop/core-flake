{
  nixpkgs,
  flake-utils,
}:
module:
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
        inherit (flake) config;
      };
      flake = evalModules {
        specialArgs = {
          inherit pkgs;
          core.compose = pkgs.callPackage ./compose.nix { };
        };
      };
    in
    flake.output;
  topLevelConfig = evalModules { };
in
{
  inherit (topLevelConfig)
    templates
    ;
}
// (flake-utils.lib.eachDefaultSystem evalSystemSpecific)
// topLevelConfig.extraConfig
