{
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
    core-flake = {
      url = "git+ssh://git@github.com/purplenoodlesoop/core-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , core-flake
    }:
    let
      core = core-flake.lib;
      name = throw "Undefined name";
      systemSpecific = { pkgs, toolchains }:
        let

        in
        {
          devEnv = [ ];
        };
    in
    core.mkFlake {
      inherit name systemSpecific;
    };
}
