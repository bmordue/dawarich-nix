{ pkgs, ruby, racc }:

pkgs.stdenv.mkDerivation rec {
  pname = "nokogiri";
  version = "1.18.8";

  src = pkgs.fetchrubygem {
    name = pname;
    inherit version;
    sha256 = "03i1vhm1x4qjil39lqrhjzc1b6rr6i5f522i98hsdz41n8pdvfin";
  };

  buildInputs = [ ruby racc pkgs.libxml2 pkgs.libxslt pkgs.zlib ];

  # Nokogiri may require specific environment variables or patches
  # for its native compilation within the Nix build environment.
  # For example, it needs to find libxml2.
  # The standard Nix RubyGems builders usually handle this.
  # If direct mkDerivation, might need:
  #   configureFlags = [
  #     "--use-system-libraries"
  #     "--with-xml2-include=${pkgs.libxml2.dev}/include/libxml2"
  #     "--with-xml2-lib=${pkgs.libxml2.out}/lib"
  #     "--with-xslt-lib=${pkgs.libxslt.out}/lib"
  #     "--with-xslt-include=${pkgs.libxslt.dev}/include"
  #   ];
  # However, when using fetchrubygem and standard build phases, often not needed.
  # Let's rely on the default gem build process first.

  propagatedBuildInputs = [ racc ]; # racc is a runtime dependency

  meta = with pkgs.lib; {
    description = "An HTML, XML, SAX, and Reader parser";
    homepage = "https://nokogiri.org";
    license = licenses.mit;
    platforms = platforms.all;
  };
}
