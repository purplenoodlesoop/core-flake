{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    pipe
    mkOption
    mapAttrs
    getExe
    flip
    mergeAttrs
    const
    ;
  inherit (lib.types)
    listOf
    lazyAttrsOf
    anything
    package
    submodule
    ;

  # `lazyAttrsOf` rather than `attrsOf`: the module system must not force an
  # output's value merely to learn the attribute's name. Keeping these lazy is
  # what lets a consumer touch one system's outputs -- or only the top-level,
  # system-independent ones -- without instantiating nixpkgs for every system.
  attrsOfPackages = lazyAttrsOf package;
  mkOptions = options: {
    options = mapAttrs (const mkOption) options;
  };
  anyAttrs = {
    default = { };
    type = lazyAttrsOf anything;
  };
  mkOptionsWithExtraConfig = flip pipe [
    (mergeAttrs {
      extraConfig = anyAttrs;
    })
    mkOptions
  ];
  flake = mkOptionsWithExtraConfig {
    apps = {
      description = "Runnable applications that are built by nix and can be run by using `nix run .#name`";
      default = { };
      type = attrsOfPackages;
    };
    packages = {
      description = "Packages that are built by nix using `nix build`, can be used by other packages";
      default = { };
      type = attrsOfPackages;
    };
    shell = {
      description = "A list of packages to be included in the shell, entered by `nix develop`";
      default = [ ];
      type = listOf package;
    };
    devShells = {
      description = "A list of shells to be built besides the default one";
      default = { };
      type = lazyAttrsOf anything;
    };
    output = {
      default = { };
      type = lazyAttrsOf anything;
    };
  };
  options = mkOptions {
    flake = {
      default = { };
      type = submodule flake;
    };
  };
  mkApp = name: pkg: {
    type = "app";
    program = "${pkg}/bin/${name}";
  };
  inherit (config.flake)
    packages
    apps
    shell
    devShells
    ;
in
options
// {
  config.flake.output = {
    inherit packages;
    apps = mapAttrs mkApp apps;
    devShells = devShells // {
      default = pkgs.mkShell {
        name = "default";
        packages = shell;
      };
    };
  };
}
