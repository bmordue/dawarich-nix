with (import <nixpkgs> {});
#let
#  gems = bundlerEnv {
#    name = "dawarich-gems";
#    ruby = ruby_3_4;
#    gemdir = ./.;
#  };
#in
 stdenv.mkDerivation {
  name = "dawarich-shell";
  buildInputs = [bundix ruby_3_4 ];
}

