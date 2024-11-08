{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    core-flake = {
      url = "github:purplenoodlesoop/core-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs:
    inputs.core-flake.lib.evalFlake {
      imports = [
        ./.
      ];
    };
}
