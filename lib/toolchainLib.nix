{ nixpkgs }: {
  merge = toolchains:
    let
      mergToolchains = acc: toolchain: {
        nativeBuild = acc.nativeBuild // (toolchain.nativeBuild or { });
        build = acc.build // (toolchain.build or { });
        dev = acc.dev // (toolchain.dev or { });
      };
      emptyToolchain = {
        nativeBuild = { };
        build = { };
        dev = { };
      };
    in
    builtins.foldl' mergToolchains emptyToolchain toolchains;
  devEnv = toolchain: builtins.attrValues (
    (toolchain.dev or { })
    // (toolchain.nativeBuild or { })
    // (toolchain.build or { })
  );
}
