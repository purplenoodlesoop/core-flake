{
  lib,
  pkgs,
  core,
  config,
  ...
}:
let
  inherit (builtins)
    map
    ;
  inherit (pkgs)
    linkFarm
    ;
  inherit (core.compose)
    writeJSON
    ;
  inherit (lib)
    mkOption
    pipe
    flatten
    attrValues
    mapAttrs
    const
    ;
  inherit (lib.types)
    listOf
    attrsOf
    raw
    submodule
    str
    package
    ;
  composeProject = submodule {
    options = {
      images = mkOption {
        type = listOf package;
        default = [ ];
        description = "Docker images (dockerTools) do be loaded";
      };

      link = mkOption {
        type = attrsOf str;
        default = { };
      };

      yml = mkOption {
        type = raw;
        default = { };
      };
    };
  };
  pipeModules = pipe (attrValues config.compose);
  collectedImages = pipeModules [
    (map (module: module.images))
    flatten
  ];
  mkSubCompose =
    {
      link,
      yml,
      ...
    }:
    let
      compose = writeJSON yml;
      name = ".limbs.json";
      project = link // {
        ${name} = compose;
      };
    in
    "${linkFarm "project" project}/${name}";
  joined = pipeModules [
    (map mkSubCompose)
    (
      include:
      writeJSON {
        inherit include;
      }
    )
  ];
  docker = cmd: "docker ${cmd}";
  loadImage = image: docker "image load -i ${image}";
  compose = cmd: "${docker "compose --file ${joined}"} ${cmd}";
  composeTasks = mapAttrs (const compose) {
    compose-pull = "pull";
    compose-up = ''
      \
       --progress plain \
       up \
       --detach \
       --remove-orphans \
       --timestamps
    '';
    compose-list = "ls";
  };
in
{
  imports = [
    ./tasks.nix
  ];

  options.compose = mkOption {
    default = { };
    type = attrsOf composeProject;
  };

  config.tasks = composeTasks // {
    compose-load = map loadImage collectedImages;
    compose-apply = with config.tasks; [
      compose-load
      compose-pull
      compose-up
      compose-list
    ];
  };
}
