{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    core-flake = {
      url = "github:purplenoodlesoop/core-flake/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      core-flake,
    }:
    let
      core = core-flake.lib;
      name = "example";
      systemSpecific =
        { pkgs, system }:
        let

        in
        {
          # shells = {};
          # apps = {};
          # packages = {};
        };
    in
    core.mkFlake {
      inherit name systemSpecific;
    };
}
