{ writeText }:
let
  inherit (builtins)
    toJSON
    mapAttrs
    listToAttrs
    ;
  fragment = "fragment";
  writeJSON = data: writeText "${fragment}.json" (toJSON data);
in
{
  inherit writeJSON;

  mkConfig = input: mapAttrs (_: path: writeJSON (import path input));

  copyFrom =
    src: dst:
    listToAttrs (
      map (name: {
        inherit name;
        value = "${src}/${name}";
      }) dst
    );

}
