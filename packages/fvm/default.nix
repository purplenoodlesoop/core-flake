{
  pkgs,
  ...
}:
{
  flake.packages = with pkgs; {
    inherit fvm;
  };
}
