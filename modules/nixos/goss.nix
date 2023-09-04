{ config, lib, pkgs, ... }:

let
  cfg = config.services.goss;

  settingsFormat = pkgs.formats.yaml { };
  configFile = settingsFormat.generate "goss.yaml" cfg.settings;

  env =
    { GOSS_FILE = cfg.configFile;
      GOSS_LOGLEVEL = cfg.logLevel;
      GOSS_LISTEN = cfg.listen;
    } // cfg.extraEnv;

in {
  meta.maintainers = [ lib.maintainers.anthonyroussel ];

  options = {
    services.goss = {
      enable = lib.mkOption {
        default = false;
        description = lib.mdDoc ''Whether to enable Goss daemon.'';
        type = lib.types.bool;
      };

      package = lib.mkPackageOptionMD pkgs "goss" {};

      listen = lib.mkOption {
        default = ":8080";
        description =  lib.mdDoc ''
          Address to wait for incoming SMTP connections on. See
          clamsmtpd.conf(5) for more details.
        '';
        type = lib.types.nullOr lib.types.str;
      };

      configFile = lib.mkOption {
        default = "/etc/goss/goss.yaml";
        description = lib.mdDoc ''
          Path to goss config file.
          Setting this option will override any configuration applied by the settings option.
        '';
        type = lib.types.nullOr lib.types.path;
      };

      settings = lib.mkOption {
        default = {};
        description = lib.mdDoc ''
          The global options in `config` file in ini format.
        '';
        type = lib.types.submodule {
          freeformType = settingsFormat.type;
        };
      };

      logLevel = lib.mkOption {
        default = "fatal";
        description = lib.mdDoc ''Goss logging level.'';
        type = lib.types.str; # enum
      };

      extraEnv = lib.mkOption {
        default = {};
        description = lib.mdDoc "Extra environment variables for Hydra.";
        type = lib.types.attrsOf lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    users.users.goss = {
      name = "goss";
      group = "goss";
      description = "goss user";
      isSystemUser = true;
      home = "/var/lib/goss";
    };

    users.groups.goss = {};

    environment.etc."goss/goss.yaml".source = configFile;

    systemd.services.goss = {
      description = "goss server";

      after = [ "network.target" "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];

      environment = env;

      reloadTriggers = [ configFile ];

      serviceConfig = {
        ConfigurationDirectory = "goss";
        ConfigurationDirectoryMode = "0750";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        ExecStart = "${cfg.package}/bin/goss serve";
        Group = "goss";
        LimitNOFILE = 16384;
        LogsDirectory = "goss";
        LogsDirectoryMode = "0750";
        PIDFile = "/run/goss/server.pid";
        Restart = "on-failure";
        RestartSec = 5;
        RuntimeDirectory = "goss";
        StateDirectory = "goss";
        StateDirectoryMode = "0750";
        User = "goss";
        WorkingDirectory = "/var/lib/goss";

        # Hardening
        DeviceAllow = [];
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateUsers = true;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
          "AF_UNIX"
          "AF_PACKET"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        UMask = "0077";
      };
    };
  };
}
