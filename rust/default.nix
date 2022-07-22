{
  apps.cargo = { pkgs, buildInputs ? [ ] }:
    let cargo = pkgs.cargo.overrideAttrs (oldAttrs: {
      buildInputs =
        (pkgs.lib.lists.optionals (builtins.hasAttr "buildInputs" oldAttrs) oldAttrs.buildInputs)
        ++ buildInputs;
    });
    in
    {
      type = "app";
      program = "${cargo}/bin/cargo";
    };

  mkRustBinary = pkgs:
    with builtins;
    { src
    , checkFmt ? true
    , rust ? null
    , name ? null
    , nativeBuildInputs ? [ ]
    , preCheck ? ""
    , ...
    }@args:
    let
      cargoToml = builtins.fromTOML (builtins.readFile (src + "/Cargo.toml"));
      nameAttrs =
        if name == null then {
          pname = cargoToml.package.name;
          version = cargoToml.package.version;
        }
        else { inherit name; }
      ;
    in
    pkgs.rustPlatform.buildRustPackage (nameAttrs // args // {
      nativeBuildInputs =
        nativeBuildInputs ++
          (pkgs.lib.optional (! isNull rust) rust) ++
          (pkgs.lib.optionals (checkFmt) [ pkgs.rustfmt ]);

      preCheck =
        if checkFmt
        then ''
          cargo fmt --check
          ${preCheck}
        ''
        else preCheck;

      cargoLock = {
        lockFile = src + "/Cargo.lock";
      };

    });

}
