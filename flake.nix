{
  description = "Abstractions for Nix flake development.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
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
      core.flake = {
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
      };
    in
    evalFlake {
      modules = [
        core
        # ./packages/fvm
        # ./lib/modules/tasks.nix
        # ./example/tasks.nix
      ];
    };
}
