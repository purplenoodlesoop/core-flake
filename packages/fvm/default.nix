{
  nixpkgs,
  pkgs,
  ...
}:
let
  name = "fvm";
  overlay = self: super: {
    ${name} = self.callPackage ./package.nix {
      inherit name;
    };
  };
  overladed = import nixpkgs {
    inherit (pkgs) system;
    overlays = [ overlay ];
  };
in
{
  flake = {
    packages = with overladed; {
      inherit fvm;
    };
    overlays.${name} = overlay;
  };
}
