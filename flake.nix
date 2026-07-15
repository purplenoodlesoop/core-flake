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
      overlay = import ./packages/fvm/overlay.nix;
    in
    evalFlake {
      # nixpkgs unstable dropped x86_64-darwin; evaluating it throws.
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      overlays = [ overlay ];
      topLevel = {
        overlays.fvm = overlay;
        templates.default = {
          description = "Default template.";
          path = ./template;
        };
        nixosModules = {
          tasks = ./lib/modules/tasks.nix;
          compose = ./lib/modules/compose.nix;
        };
        lib = {
          inherit evalFlake;
        };
      };
      perSystem.imports = [
        ./packages/fvm
        ./lib/modules/tasks.nix
      ];
    };
}
