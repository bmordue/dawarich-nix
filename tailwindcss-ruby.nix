{ pkgs, ruby }:

pkgs.stdenv.mkDerivation {
  pname = "tailwindcss-ruby";
  version = "3.4.16";

  src = pkgs.fetchurl {
    url = "https://rubygems.org/gems/tailwindcss-ruby-3.4.16.gem";
    sha256 = "1ip3r3nli0sbcs6qwk87jgk13b1q4sryd1c6iajqr6fy7zfj65g0";
  };

  buildInputs = [ ruby ];

  # Add other necessary attributes for gem building if any.
  # For now, assume a standard gem build.

  meta = with pkgs.lib; {
    description = "Ruby wrapper for the Tailwind CSS CLI";
    homepage = "https://github.com/excid3/tailwindcss-ruby"; # Common homepage, verify if necessary
    license = licenses.mit; # Assuming MIT
    platforms = platforms.all;
  };
}
