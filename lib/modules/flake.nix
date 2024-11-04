{
  lib,
  ...
}:
let
  inherit (lib)
    pipe
    mkOption
    mapAttrs
    flip
    mergeAttrs
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
  packages = attrsOf package;
  mapToOptions = mapAttrs (name: option: mkOption option);
  mkOptions = options: {
    options = mapToOptions options;
  };
  extraConfigOption = {
    extraConfig = {
      default = { };
      type = attrsOf anything;
    };
  };
  withExtraConfig = pipe extraConfigOption [
    mapToOptions
    mergeAttrs
  ];
  mkOptionsWithExtraConfig = flip pipe [
    withExtraConfig
    mkOptions
  ];
  perSystem = mkOptionsWithExtraConfig {
    apps = {
      default = { };
      type = packages;
    };
    packages = {
      default = { };
      type = packages;
    };
    shell = {
      default = [ ];
      type = listOf package;
    };
  };
  template = mkOptions {
    description = {
      default = "";
      type = str;
    };
    path.type = path;
  };
  flake = mkOptionsWithExtraConfig {
    perSystem = {
      default = { };
      type = submodule perSystem;
    };
    templates = {
      default = { };
      type = attrsOf (submodule template);
    };
  };
in
mkOptions {
  flake = {
    default = { };
    type = submodule flake;
  };
}
