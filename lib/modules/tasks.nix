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
    map
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
    const
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
        body = mkOption {
          description = "Task body with potential dependencies";
          type = linesOr (listOf taskSubmodule);
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
    body:
    if isString body then
      [ body ]
    else if isList body then
      concatMap processTaskBody body
    else
      "./${getExe apps.${body.name}}";
  mkTaskPackage =
    name: input:
    writeShellApplication {
      inherit name;
      text = pipe (input) [
        processTaskBody
        (concatStringsSep "\n")
      ];
    };

in
{
  imports = [
    ./flake.nix
  ];

  options.tasks = mkOption {
    # type = attrsOf (linesOr taskSubmodule);
    type = attrsOf lines;
    default = { };
  };

  config = {
    tasks.tasks-help = {
      description = "Help message for enabled tasks";
      body = pipe tasks [
        attrValues
        (map (task: "\\t${task.name} - ${task.description}"))
        (descriptions: [ "${tasksAmount} tasks are available." ] ++ descriptions ++ [ "" ])
        (concatStringsSep "\\n")
        (description: ''
          printf "${description}"
        '')
      ];
    };
    flake.shell = attrValues apps;
  };
}
