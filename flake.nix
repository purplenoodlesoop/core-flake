{
  description = "Abstractions for Nix flake development.";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
    flake-utils.url = "https://flakehub.com/f/numtide/flake-utils/*.tar.gz";
    fh = {
      url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , fh
    , flake-utils
    }:
    let
      mkFlake = import ./lib/mkFlake.nix {
        inherit self nixpkgs flake-utils fh;
      };
    in
    mkFlake {
      name = "core";
      systemSpecific = { pkgs, toolchains }: {
        packages = {
          fvm = import ./packages/fvm/shell.nix { inherit pkgs; };
        };
      };
      lib = {
        inherit mkFlake;
        toolchain = import ./lib/toolchainLib.nix { inherit nixpkgs; };
      };
      templates.default = {
        description = "Default template.";
        path = ./template;
      };
    };
}
    
