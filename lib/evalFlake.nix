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
      config = evalModules {
        specialArgs = rec {
          pkgs = nixpkgs.legacyPackages.${system};
          core.compose = pkgs.callPackage ./compose.nix { };
        };
      };
    in
    config.output;
  topLevelConfig = evalModules { };
in
{
  inherit (topLevelConfig)
    templates
    ;
}
// (flake-utils.lib.eachDefaultSystem evalSystemSpecific)
// topLevelConfig.extraConfig
