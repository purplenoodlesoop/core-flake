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
    path
    attrsOf
    anything
    str
    package
    submodule
    ;

  attrsOfPackages = attrsOf package;
  mkOptions = options: {
    options = mapAttrs (const mkOption) options;
  };
  mkOptionsWithExtraConfig = flip pipe [
    (mergeAttrs {
      extraConfig = {
        default = { };
        type = attrsOf anything;
      };
    })
    mkOptions
  ];
  template = mkOptions {
    description = {
      default = "";
      type = str;
    };
    path.type = path;
  };
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
    templates = {
      default = { };
      type = attrsOf (submodule template);
    };
    output = {
      default = { };
      type = attrsOf anything;
    };
  };
  options = mkOptions {
    flake = {
      default = { };
      type = submodule flake;
    };
  };

  mkApp = pkg: {
    type = "app";
    program = getExe pkg;
  };
  inherit (config.flake)
    packages
    apps
    shell
    ;
in
options
// {
  config.flake.output = {
    inherit packages;
    apps = mapAttrs mkApp apps;
    devShells.default = pkgs.mkShell {
      name = "default";
      packages = shell;
    };
  };
}