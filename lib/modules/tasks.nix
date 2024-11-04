{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (pkgs)
    writeShellApplication
    writeShellScript
    ;
  inherit (builtins)
    map
    isString
    toString
    mapAttrs
    concatStringsSep
    concatMap
    length
    ;
  inherit (lib)
    mkOption
    pipe
    concat
    const
    mkEnableOption
    getExe
    flip
    ;
  inherit (lib.types)
    listOf
    attrsOf
    str
    lines
    package
    either
    submodule
    ;
  inherit (lib.attrsets)
    attrNames
    attrValues
    ;
  inherit (config)
    tasks
    ;

  linesOr = either lines;
  taskSubmodule = submodule (
    { name, ... }:
    {
      options = {
        enable = (mkEnableOption name) // {
          default = true;
        };
        name = mkOption {
          description = "Task name";
          type = str;
          default = name;
        };
        description = mkOption {
          description = "Task description";
          type = str;
          default = "Task ${name}";
        };
      };
      # body = mkOption {
      #   description = "Task body with potential dependencies";
      #   type = linesOr (listOf (linesOr taskSubmodule));
      # };
    }
  );
  taskNames = attrNames tasks;
  tasksAmount = pipe taskNames [
    length
    toString
  ];
  mkTaskPackage =
    {
      name,
      description,
      # body,
      ...
    }:
    writeShellApplication {
      inherit name;
      meta = {
        inherit description;
      };
      text = # _
        "";
      # if isString body then
      #   body
      # else
      #   pipe body [
      #     (map (line: if isString line then writeShellScript "task" line else config.apps.${line.name}))
      #     (map (line: "./${getExe line}"))
      #     (concatStringsSep "\n")
      #   ];
    };
  taskPackages = mapAttrs (const mkTaskPackage) tasks;
  tasks-help = writeShellApplication {
    name = "tasks-help";
    meta.description = "Help message for enabled tasks";
    text = pipe taskNames [
      (map (name: tasks.${name}))
      (map (task: "\\t${task.name} - ${task.description}"))
      (tasks: [ "${tasksAmount} tasks are available." ] ++ tasks ++ [ "" ])
      (concatStringsSep "\\n")
      (description: ''
        printf "${description}"
      '')
    ];
  };
  apps = taskPackages // {
    inherit tasks-help;
  };
in
{
  options.tasks = mkOption {
    type = attrsOf taskSubmodule;
    default = { };
  };

  config.flake.perSystem = {
    inherit apps;
    shell = attrValues apps;
  };
}
