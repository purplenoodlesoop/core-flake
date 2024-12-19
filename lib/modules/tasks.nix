{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (pkgs)
    writeShellApplication
    ;
  inherit (builtins)
    isString
    isList
    toString
    mapAttrs
    concatStringsSep
    concatMap
    length
    ;
  inherit (lib)
    mkOption
    pipe
    mkEnableOption
    getExe
    ;
  inherit (lib.types)
    listOf
    attrsOf
    str
    lines
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
  taskBody = linesOr (listOf (either taskBody (linesOr taskSubmodule)));
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
          default = "";
        };
        body = mkOption {
          description = "Task body with potential dependencies";
          type = taskBody;
        };
      };
    }
  );
  taskNames = attrNames tasks;
  tasksAmount = pipe taskNames [
    length
    toString
  ];
  apps = mapAttrs mkTaskPackage tasks;
  processTaskBody =
    initial: body:
    let
      process = processTaskBody false;
    in
    if isString body then
      [ body ]
    else if isList body then
      concatMap process body
    else if initial then
      process body.body
    else
      "./${getExe apps.${body.name}}";
  mkTaskPackage =
    name: input:
    writeShellApplication {
      inherit name;
      text = pipe input [
        (processTaskBody true)
        (concatStringsSep "\n")
      ];
    };
in
{
  imports = [
    ./flake.nix
  ];

  options.tasks = mkOption {
    type = attrsOf (either taskSubmodule taskBody);
    default = { };
  };

  config = {
    tasks.tasks-help = {
      description = "Help message for enabled tasks";
      body = pipe tasks [
        (mapAttrs (
          name: task: "\\t${name} - ${if builtins.isAttrs task then task.description else "Task ${name}"}"
        ))
        attrValues
        (descriptions: [ "${tasksAmount} tasks are available." ] ++ descriptions ++ [ "" ])
        (concatStringsSep "\\n")
        (description: ''
          printf "${description}"
        '')
      ];
    };

    flake = {
      inherit apps;
      shell = attrValues apps;
    };
  };
}
