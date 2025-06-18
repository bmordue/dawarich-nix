{ config, lib, pkgs, ... }:

let
  cfg = config.services.dawarich;
  dawarich = pkgs.callPackage ./package.nix {};

  env = {
    RAILS_ENV = "production";
    NODE_ENV = "production";

    DATABASE_HOST = "localhost";
    DATABASE_USERNAME = "dawarich";
    DATABASE_PASSWORD = "dawarich";
    DATABASE_NAME = "dawarich";
    DATABASE_PORT = "5432";

    MIN_MINUTES_SPENT_IN_CITY = "60";
    
    APPLICATION_HOSTS = "localhost";
    APPLICATION_PROTOCOL = "http";
    TIME_ZONE = "Europe/London";

    DISTANCE_UNIT = "km";
    RAILS_MAX_THREADS = "5";
    BACKGROUND_PROCESSING_CONCURRENCY = "5";
    PROMETHEUS_EXPORTER_ENABLED = "false";
    PROMETHEUS_EXPORTER_HOST = "0.0.0.0";
    PROMETHEUS_EXPORTER_PORT = "9394";

    PHOTON_API_USE_HTTPS = "";
    PHOTON_API_KEY = "";

    GEOAPIFY_API_KEY = "";
    SMTP_SERVER = "";
    SMTP_PORT = "";
    SMTP_DOMAIN = "";
    SMTP_USERNAME = "";
    SMTP_PASSWORD = "";
    SMTP_FROM = "";

    # SQLite database paths for secondary databases
    QUEUE_DATABASE_PATH = "/var/lib/dawarich/db/dawarich_queue.sqlite3";
    CACHE_DATABASE_PATH = "/var/lib/dawarich/db/dawarich_cache.sqlite3";
    CABLE_DATABASE_PATH = "/var/lib/dawarich/db/dawarich_cable.sqlite3";

    SELF_HOSTED = "true";
    STORE_GEODATA = "true";

    SECRET_KEY_BASE = "battery-horse-stapler-insecure";
  };

  # borrowed from mastodon.nix
  cfgService = {
    # User and group
    User = "dawarich"; #cfg.user;
    Group = "dawarich"; #cfg.group;
    # Working directory
    WorkingDirectory = dawarich;
    # State directory and mode
    StateDirectory = "dawarich";
    StateDirectoryMode = "0750";
    # Logs directory and mode
    LogsDirectory = "dawarich";
    LogsDirectoryMode = "0750";
    # Proc filesystem
    ProcSubset = "pid";
    ProtectProc = "invisible";
    # Access write directories
    UMask = "0027";
    # Security
    NoNewPrivileges = true;
    # Sandboxing
    ProtectSystem = "strict";
    ProtectHome = true;
    PrivateTmp = true;
    PrivateDevices = true;
    PrivateUsers = true;
    ProtectClock = true;
    ProtectHostname = true;
    ProtectKernelLogs = true;
    ProtectKernelModules = true;
    ProtectKernelTunables = true;
    ProtectControlGroups = true;
    RestrictAddressFamilies = [
      "AF_UNIX"
      "AF_INET"
      "AF_INET6"
      "AF_NETLINK"
    ];
    RestrictNamespaces = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = false;
    RestrictRealtime = true;
    RestrictSUIDSGID = true;
    RemoveIPC = true;
    PrivateMounts = true;
    # System Call Filtering
    SystemCallArchitectures = "native";
    RuntimeDirectory = "dawarich";
    RuntimeDirectoryMode = "0755";
  };

in {
  options.services.dawarich = {
    enable = lib.mkEnableOption "dawarich";
    package = dawarich;
  };

  config = lib.mkIf cfg.enable {
     
     services.postgresql = {
       enable = true;
       ensureDatabases = [ "dawarich" ];
       ensureUsers = [{
         name = "dawarich";
         ensureDBOwnership = true;
         ensureClauses.login = true;
         ensureClauses.superuser = true; # to add postgis in rb script
       }];
       package = pkgs.postgresql_15;
       extensions = ps: with pkgs.postgresql_15.pkgs; [ postgis ];
     };

    systemd.services.dawarich-init-db = {
      enable = true;

      description = "Dawarich Database Initialization";
      after = [
        "postgresql.service"
      ];
      requires = [ 
        "postgresql.service"
      ];

      # based on dawarich/docker/web-entrypoint.sh
      script = ''
        #!/bin/sh
        set -e
        export RAILS_ENV="${env.RAILS_ENV}"
 #       export DATABASE_HOST="${env.DATABASE_HOST}"
 #       export DATABASE_PORT="${env.DATABASE_PORT}"
 #       export DATABASE_USERNAME="${env.DATABASE_USERNAME}"
 #       export DATABASE_PASSWORD="${env.DATABASE_PASSWORD}"
        export DATABASE_NAME="${env.DATABASE_NAME}"
        export SECRET_KEY_BASE="${env.SECRET_KEY_BASE}"
 
        export SELF_HOSTED=true

        SQLITE_DB_DIR="$STATE_DIRECTORY/db"
        mkdir -p $SQLITE_DB_DIR
        echo "Created SQLite database directory at $SQLITE_DB_DIR"

        # Setup Queue database with SQLite
        QUEUE_DATABASE_PATH="$SQLITE_DB_DIR/${env.DATABASE_NAME}_queue.sqlite3"
        export QUEUE_DATABASE_PATH
        echo "✅ SQLite queue database configured at $QUEUE_DATABASE_PATH"

        # Setup Cache database with SQLite
        CACHE_DATABASE_PATH="$SQLITE_DB_DIR/${env.DATABASE_NAME}_cache.sqlite3"
        export CACHE_DATABASE_PATH
        echo "✅ SQLite cache database configured at $CACHE_DATABASE_PATH"

        # Setup Cable database with SQLite (only for production and staging)
        if [ "${env.RAILS_ENV}" = "production" ] || [ "${env.RAILS_ENV}" = "staging" ]; then
          CABLE_DATABASE_PATH="$SQLITE_DB_DIR/${env.DATABASE_NAME}_cable.sqlite3"
          export CABLE_DATABASE_PATH
          echo "✅ SQLite cable database configured at $CABLE_DATABASE_PATH"
        fi

        cd ${dawarich}/share/dawarich

	TAILWINDCSS_INSTALL_DIR=/var/lib/dawarich/tmp/tailwindcss
	${dawarich}/bin/bundle exec rails assets:precompile

        # Run primary database migrations first (needed before SQLite migrations)
        echo "Running primary database migrations..."
        ${dawarich}/bin/bundle exec rails db:migrate

        # Run SQLite database migrations
        echo "Running cache database migrations..."
        ${dawarich}/bin/bundle exec rails db:migrate:cache

        echo "Running queue database migrations..."
        ${dawarich}/bin/bundle exec rails db:migrate:queue

        # Run cable migrations for production/staging
        if [ "${env.RAILS_ENV}" = "production" ] || [ "${env.RAILS_ENV}" = "staging" ]; then
          echo "Running cable database migrations..."
          ${dawarich}/bin/bundle exec rails db:migrate:cable
        fi

        # Run data migrations
        echo "Running DATA migrations..."
        ${dawarich}/bin/bundle exec rake data:migrate

        echo "Running seeds..."
        ${dawarich}/bin/bundle exec rails db:seed
        echo "✅ Database initialization complete!"
        
        '';

        serviceConfig = {
          Type = "oneshot";
          SyslogIdentifier = "dawarich-init-db";
#          User = "dawarich";
#          Group = "dawarich";
#          Environment = env;
#          StateDirectory = "dawarich";
        } // cfgService;
    };


systemd.services.dawarich = {
  description = "dawarich service";
  wantedBy = [ "multi-user.target" ];
      requires = [ 
        "dawarich-init-db.service" 
        "postgresql.service"
      ];
      after = [
        "network.target" 
        "dawarich-init-db.service" 
        "postgresql.service"
      ];

  environment = env;
  
  script = ''
      export RAILS_ROOT=/var/lib/dawarich/share/dawarich
      export TMPDIR=/var/lib/dawarich/tmp
      export TMP=/var/lib/dawarich/tmp
      export TEMP=/var/lib/dawarich/tmp

      mkdir -p $TMP/cache/assets/
      mkdir -p /var/lib/dawarich/share/dawarich/tmp/cache/assets

      export SELF_HOSTED=true
      export DATABASE_NAME=dawarich

      export PIDFILE=$TMP/puma.pid

#      "${pkgs.coreutils}/bin/cp -r ${dawarich}/* /var/lib/dawarich/"  #*/
#      "${pkgs.coreutils}/bin/chmod -R u+w /var/lib/dawarich"

      cd /var/lib/dawarich/share/dawarich
      echo "Starting rails server..."
      /var/lib/dawarich/bin/rails server -p 3000 -b 127.0.0.1

  '';

  serviceConfig = {
  } // cfgService;
};
 
    users.users.dawarich = {
      isSystemUser = true;
      group = "dawarich";
      description = "Dawarich service user";
    };
 
    users.groups.dawarich = {};
    environment.systemPackages = [ dawarich ];
  };

}
