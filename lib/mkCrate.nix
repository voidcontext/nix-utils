{ pkgs, rustToolchain, crane, ... }:

with builtins;
with pkgs.lib;
let fromCargoToml = src: path: attrsets.getAttrFromPath path (fromTOML (readFile (src + "/Cargo.toml")));
in
{ src
, pname ? fromCargoToml src [ "package" "name" ]
, version ? fromCargoToml src [ "package" "version" ]
}:
let
  nativeBuildInputs = with pkgs.lib;
    (optional pkgs.stdenv.isLinux pkgs.pkg-config) ++ [ pkgs.cmake ];

  buildInputs = with pkgs.lib;
    (optional pkgs.stdenv.isLinux pkgs.openssl) ++
    (optional (pkgs.system == "x86_64-darwin")
      pkgs.darwin.apple_sdk.frameworks.Security);

  craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;

  commonArgs = {
    src = craneLib.cleanCargoSource src;

    inherit buildInputs nativeBuildInputs;
  };

  deps = craneLib.buildDepsOnly (commonArgs // {
    inherit pname version;
  });

  package = craneLib.buildPackage {
    src = craneLib.cleanCargoSource src;
    inherit pname version;
    cargoArtifacts = deps;
    preCheck = ''
      cargo fmt --check
      cargo clippy  -- -W clippy::pedantic -A clippy::missing-errors-doc -A clippy::missing-panics-doc
    '';

    inherit buildInputs nativeBuildInputs;
  };
in
{
  inherit
    package
    rustToolchain
    buildInputs
    nativeBuildInputs;
}