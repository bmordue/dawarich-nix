{ pkgs, ruby, railties, tailwindcss-ruby }:

pkgs.stdenv.mkDerivation {
  pname = "tailwindcss-rails";
  version = "3.3.2";

  src = pkgs.fetchurl {
    url = "https://rubygems.org/gems/tailwindcss-rails-3.3.2.gem";
    sha256 = "02vg7lbb95ixx9m6bgm2x0nrcm4dxyl0dcsd7ygg6z7bamz32yg8";
  };

  buildInputs = [ ruby railties tailwindcss-ruby ];

  # Add other necessary attributes for gem building if any,
  # like native build inputs or patches.
  # For now, assume a standard gem build.

  meta = with pkgs.lib; {
    description = "Rails integration for the Tailwind CSS framework";
    homepage = "https://github.com/rails/tailwindcss-rails";
    license = licenses.mit; # Assuming MIT based on common Rails gems
    platforms = platforms.all;
  };
}
