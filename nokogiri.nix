{ pkgs ? import <nixpkgs> {}, stdenv, ruby }:

stdenv.mkDerivation rec {
  pname = "nokogiri";
  version = "1.18.8"; # Fetched from gemset.nix

  src = pkgs.fetchrubygem {
    name = "nokogiri";
    inherit version;
    sha256 = "03i1vhm1x4qjil39lqrhjzc1b6rr6i5f522i98hsdz41n8pdvfin"; # Fetched from gemset.nix
  };

  buildInputs = with pkgs; [
    libxml2
    libxslt
    zlib
    ruby
  ] ++ (if pkgs.stdenv.isDarwin then [ libiconv ] else [ ]);

  # If the gem has specific build instructions or patches, add them here.
  # For many gems, the default buildPhase and installPhase provided by mkDerivation are sufficient.

  meta = with pkgs.lib; {
    description = "An HTML, XML, SAX, and Reader parser with XPath and CSS selector support";
    homepage = "https://nokogiri.org";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = [ maintainers.Freika ]; # Or your GitHub handle
  };
}
