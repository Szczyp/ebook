{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.ebook;
in
{
  options.services.ebook = {
    enable = mkEnableOption "ebook";

    config = mkOption {
      type        = types.str;
      description = ''
        YAML config.
      '';
    };

    interval = mkOption {
      type        = types.str;
      default     = "minutely";
      example     = "hourly";
      description = ''
        Run at this interval. Every minute by default.
      '';
    };

    workDir = mkOption {
      type = types.str;
      default = "/var/lib/ebook";
      description = ''
        Working directory for ebook service. Mainly for storing urlextract cache.
      '';
    };

    user = mkOption {
      type        = types.str;
      default     = "ebook";
      description = ''
          Ebook service user account.
      '';
    };

    group = mkOption {
      type        = types.str;
      default     = "ebook";
      description = ''
          Primary group of the Ebook service user account.
      '';
    };
  };

  config = mkIf cfg.enable ({
    systemd.services.ebook = {
      description = "Ebook service";
      path        = [ pkgs.ebook ];
      script      = ''
        exec ebook --config ${pkgs.writeTextFile { name = "config.yaml"; text = cfg.config; }}
      '';
      serviceConfig = {
        User  = cfg.user;
        Group = cfg.group;
      };
    };

    systemd.timers.ebook = {
      description            = "Ebook timer";
      partOf                 = [ "ebook.service" ];
      wantedBy               = [ "timers.target" ];
      timerConfig.OnCalendar = cfg.interval;
    };

    users.users.${cfg.user} = {
      isSystemUser = true;
      description  = "Ebook service user";
      group        = cfg.group;
      home         = cfg.workDir;
      createHome   = true;
    };

    users.groups.${cfg.group} = {};
  });
}
