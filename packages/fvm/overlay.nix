self: super: {
  fvm = self.callPackage ./package.nix {
    name = "fvm";
  };
}
