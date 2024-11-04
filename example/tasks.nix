{
  config,
  ...
}:
let
  printIn = dir: {
    description = "Print contents of ${dir}";
    body = ''
      cd ${dir}
      ls
    '';
  };
in
{
  tasks = {
    print-lib = printIn "lib";
    print-example = printIn "example";
    # print-everything = {
    #   description = "Print everything";
    #   # body = with config.tasks; [
    #   #   print-lib
    #   #   print-example
    #   # ];
    # };
  };
}
