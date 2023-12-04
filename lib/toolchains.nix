{ self
, pkgs
, lib
}:
let
  baseDev = with pkgs; { inherit git bash cloc; };
  node = pkgs.nodejs_21;
  baseToolchains = with pkgs; {
    dart.build = {
      inherit dart;
    };

    flutter.build = {
      fvm = self.packages.${system}.fvm;
    };

    ios.dev = {
      inherit cocoapods;
    };

    node = {
      nativeBuild = {
        inherit typescript node;
      };
      build = {
        inherit bash node;
      };
      dev = with nodePackages; {
        inherit nodemon ts-node;
      };
    };

    haskell = {
      build = {
        inherit ghc;
      };
      dev = with haskellPackages; {
        inherit haskell-language-server hlint cabal-install;
      } // { inherit hpack; };
    };
  };
  mergeDevPackages = _: toolchain: toolchain // { dev = baseDev // (toolchain.dev or { }); };
in
lib.mapAttrs mergeDevPackages baseToolchains
