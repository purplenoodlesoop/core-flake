{
  nixpkgs,
  flake-utils,
}:
module:
let
  inherit (flake-utils.lib)
    eachDefaultSystem
    ;
  inherit (nixpkgs.lib)
    flip
    concatAttrs
    pipe
    getExe
    mapAttrs
    ;
  getPkgs = system: nixpkgs.legacyPackages.${system};
  flake.modules = [
    ./modules/flake.nix
    module
  ];
  evalModules =
    args:
    pipe flake [
      (flip concatAttrs args)
      evalModules
      (m: m.config.flake)
    ];
  evalSystemSpecific =
    system:
    let
      pkgs = getPkgs system;
      config = evalModules {
        specialArgs = rec {
          inherit pkgs;
          core.compose = pkgs.callPackage ./compose.nix { };
        };
      };
      inherit (config) perSystem;
      mkFix = name: value: {
        app = {
          type = "app";
          program = getExe value;
        };
        shell = pkgs.mkShell {
          inherit name;
          packages = value;
        };
      };
      applyFix = type: mapAttrs (name: value: (mkFix name value).${type} or value);
      fixedPerSystem = mapAttrs applyFix perSystem;
    in
    fixedPerSystem // perSystem.extraConfig;
  systemSpecificConfig = eachDefaultSystem evalSystemSpecific;
  topLevelConfig = evalModules { };
in
{
  inherit (topLevelConfig)
    templates
    ;
}
// systemSpecificConfig
// topLevelConfig.extraConfig
