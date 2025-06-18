{ pkgs ? import <nixpkgs> {}, stdenv }:

let
  ruby = pkgs.ruby_3_4;

  nokogiriGem = pkgs.callPackage ./nokogiri.nix { inherit ruby; };
  
  # Define system packages needed for gem compilation
  gemDeps = with pkgs; [
    libxml2
    libxslt
    zlib
    nodejs
    libiconv
    postgresql
  ];
  
  # Fetch source from GitHub
  src = pkgs.fetchgit {
    url = "https://github.com/Freika/dawarich.git";
    rev = "0.27.2";
    sha256 = "sha256-ejJElNyw1ouTyXUM7/bmEVGLqOxuevjG/Jtg4klwD6M=";
#    sha256 = lib.fakeHash;
  };
  
# RubyGems Management Strategy:
# Most gems are managed via `pkgs.bundlerEnv` below. It uses the `Gemfile`,
# `Gemfile.lock`, and the `gemset.nix` (which is generated from the lock file)
# to fetch and build gems. `gemset.nix` contains the specific versions and SHA256 hashes.
#
# Gems that require special build steps, patches, or have complex system dependencies
# not easily handled by `bundlerEnv` directly (e.g., nokogiri) are packaged individually
# in separate .nix files (e.g., `nokogiri.nix`). These are then imported using `pkgs.callPackage`
# and typically use `pkgs.fetchurl` to get their source from rubygems.org.
# These individually packaged gems are then often included in the `buildInputs` of `bundlerEnv`
# or the main derivation if they are needed during the build of other gems or the application itself.
  # Create a bundler environment with all dependencies
  gems = pkgs.bundlerEnv {
    name = "dawarich-gems";
    inherit ruby;
    buildInputs = [ nokogiriGem ];
    gemdir = ./.;  # Points to current directory where Gemfile, Gemfile.lock, and gemset.nix are located
    
    # Pass build flags to bundler
#    extraConfigPaths = [ 
#      (pkgs.writeTextFile {
#        name = "bundler-config";
#        text = ''
#          ---
#          BUNDLE_FORCE_RUBY_PLATFORM: "true"
#        '';
#      }) 
#    ];
  };

  tailwindcss-ruby-drv = import ./tailwindcss-ruby.nix { inherit pkgs ruby; };
  tailwindcss-rails-drv = import ./tailwindcss-rails.nix { inherit pkgs ruby; railties = gems.railties; tailwindcss-ruby = tailwindcss-ruby-drv; };
in
stdenv.mkDerivation {
  name = "dawarich";
  inherit src;
  buildInputs = [ gems ruby gems.wrappedRuby pkgs.rubyPackages_3_4.sqlite3 pkgs.tailwindcss nokogiriGem tailwindcss-rails-drv ] ++ gemDeps;
  
  buildPhase = ''
    cp -r ${src}/. .
    chmod -R u+w .
  '';
  
  installPhase = ''
    mkdir -p $out/bin $out/share/dawarich
    cp -r . $out/share/dawarich
    cp -r ${gems}/bin/* $out/bin/
    chmod +x $out/bin/*

    # Create wrapper script for the main executable
    cat > $out/bin/dawarich <<EOF
    #!/bin/sh
    export GEM_PATH="${gems}/${gems.ruby.gemPath}"
    export BUNDLE_GEMFILE="$out/share/dawarich/Gemfile"
    cd $out/share/dawarich
    exec ${gems}/bin/bundle exec "\$@"
    EOF
    # Add any executables to $out/bin if needed
    # ln -s $out/path/to/executable $out/bin/your-app
  '';
}
