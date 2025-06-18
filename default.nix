{ config, lib, pkgs, ... }:

let 
  module = import ./module.nix { inherit config lib pkgs; };
in
{
  imports = [ module ];
  config = {
    services.dawarich.enable = true;
    # Any other service configuration options here

    services.nginx.virtualHosts = {
      "da.${config.networking.domain}" = { # TODO set up DNS
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          proxyWebsockets = true;
          proxyPass = "http://localhost:8044/"; # TODO fix port!
        };
      };
  };

  };
}

