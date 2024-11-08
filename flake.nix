{
  description = "Abstractions for Nix flake development.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }:
    let
      evalFlake = import ./lib/evalFlake.nix {
        inherit
          nixpkgs
          flake-utils
          ;
      };
      overlay = self: super: {
        fvm = self.callPackage ./packages/fvm/package.nix {
          name = "fvm";
        };
      };
    in
    evalFlake {
      overlays = [ overlay ];
      module = {
        imports = [
          ./packages/fvm
          ./lib/modules/tasks.nix
          ./lib/modules/compose.nix
        ];

        flake = {
          templates.default = {
            description = "Default template.";
            path = ./template;
          };

          extraConfig = {
            nixosModules = {
              tasks = ./lib/modules/tasks.nix;
              compose = ./lib/modules/compose.nix;
            };
            lib = {
              inherit evalFlake;
            };
          };

          overlays.fvm = overlay;
        };
      };
    };
}
