{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.app-recommender;
in
{
  options.services.app-recommender = {
    enable = mkEnableOption "AI-powered application recommendation engine";
    
    scanInterval = mkOption {
      type = types.int;
      default = 7;
      description = "How often to automatically scan for new applications and update recommendations (in days)";
    };
    
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/app-recommender";
      description = "Directory to store app recommendation database and other data";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # GTK for the GUI
      gtk3
      
      # Python and required packages
      (python3.withPackages (ps: with ps; [
        pygobject3
        pycairo
        sqlalchemy
        python-dateutil
        requests
      ]))
      
      # For hardware detection
      pciutils
      usbutils
      
      # Make our scripts available in PATH
      (pkgs.writeShellScriptBin "nixapp-recommender" ''
        #!/usr/bin/env bash
        exec ${pkgs.python3}/bin/python3 ${../app-recommender/recommender_gui.py} "$@"
      '')
    ];
    
    # Create the data directory
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0755 root root - -"
      "d '/var/log/app-recommender' 0755 root root - -"
    ];
    
    # Set up a periodic scan service
    systemd.services.app-recommender-scan = {
      description = "Scan applications and update recommendations";
      path = with pkgs; [
        python3
        bash
        coreutils
        pciutils
      ];
      environment = {
        APP_RECOMMENDER_DB = "${cfg.dataDir}/database.db";
      };
      script = ''
        mkdir -p ${cfg.dataDir}
        ${pkgs.python3}/bin/python3 ${../app-recommender/app_recommender.py} --scan --usage --recommend
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        PermissionsStartOnly = true;
      };
    };
    
    # Schedule the scan service to run periodically
    systemd.timers.app-recommender-scan = {
      description = "Timer for app-recommender-scan";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "1h";
        OnUnitActiveSec = "${toString cfg.scanInterval}d";
        RandomizedDelaySec = "1h";
        Unit = "app-recommender-scan.service";
      };
    };
    
    # Add desktop file to system menu
    environment.systemPackages = [
      (pkgs.makeDesktopItem {
        name = "nixapp-recommender";
        desktopName = "NixOS App Recommender";
        comment = "AI-powered application recommendation engine for NixOS";
        exec = "nixapp-recommender";
        icon = "system-software-install";
        terminal = false;
        categories = [ "System" "Settings" ];
        genericName = "Application Recommender";
      })
    ];
  };
}