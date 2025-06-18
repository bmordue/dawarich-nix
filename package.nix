{ pkgs ? import <nixpkgs> {}, stdenv }:

let
  ruby = pkgs.ruby_3_4;
  
  # Define system packages needed for gem compilation
  gemDeps = with pkgs; [
    libxml2
    libxslt
    zlib
    nodejs
    libiconv
  ];
  
  # Fetch source from GitHub
  src = pkgs.fetchgit {
    url = "https://github.com/Freika/dawarich.git";
    rev = "0.27.2";
    sha256 = "sha256-ejJElNyw1ouTyXUM7/bmEVGLqOxuevjG/Jtg4klwD6M=";
#    sha256 = lib.fakeHash;
  };
  
  # Create a bundler environment with all dependencies
  gems = pkgs.bundlerEnv {
    name = "dawarich-gems";
    inherit ruby;
    buildInputs = [ pkgs.rubyPackages_3_4.nokogiri];
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
in
stdenv.mkDerivation {
  name = "dawarich";
  inherit src;
  buildInputs = [ gems ruby gems.wrappedRuby pkgs.rubyPackages_3_4.sqlite3 pkgs.tailwindcss ] ++ gemDeps; #pkgs.rubyPackages_3_4.nokogiri] ++ gemDeps;
  
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
