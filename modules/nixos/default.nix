{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ./app-recommender
  ];
  
  # Common system configuration settings
  
  # Enable flakes and improve Nix experience
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" "nix-data-from-xdg" "ca-derivations" ];
      auto-optimise-store = true;
      # Allow to install packages even when signature checking fails
      allow-import-from-derivation = true;
      # Enable flakes
      warn-dirty = false;
      # Performance improvements
      max-jobs = "auto";
      cores = 0; # use all available cores
      # Better caching
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    # Add utilities for better Nix experience
    extraOptions = ''
      keep-outputs = true
      keep-derivations = true
      # Optimize for SSDs
      min-free = ${toString (100 * 1024 * 1024)}
      max-free = ${toString (1024 * 1024 * 1024)}
    '';
    optimise = {
      automatic = true;
      dates = [ "weekly" ];
    };
  };
  
  # System optimizations for Intel i3-13100F and AMD RX 6650XT
  boot.kernel.sysctl = {
    # Networking improvements
    "net.core.netdev_max_backlog" = 16384;
    "net.core.somaxconn" = 8192;
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_max_syn_backlog" = 8192;
    "net.ipv4.tcp_max_tw_buckets" = 2000000;
    "net.core.rmem_max" = 4194304;
    "net.core.wmem_max" = 1048576;
    
    # VM improvements for i3-13100F (quad-core) with good RAM
    "vm.swappiness" = 5; # Minimize swapping for better responsiveness
    "vm.dirty_background_ratio" = 5;
    "vm.dirty_ratio" = 10;
    "vm.vfs_cache_pressure" = 40; # Keep directory entries cached longer for gaming
    "vm.dirty_writeback_centisecs" = 1500; # 15 seconds for better desktop performance
    "vm.dirty_expire_centisecs" = 1500;
    "vm.max_map_count" = 2147483642; # Helps with games using lots of memory maps
    "vm.dirty_background_bytes" = 16777216;  # 16MB - Better control of background IO
    "vm.dirty_bytes" = 50331648;  # 48MB - Better control of dirty data flushing
    
    # CPU scheduler optimizations for Intel i3-13100F
    "kernel.sched_min_granularity_ns" = 10000000; # 10ms
    "kernel.sched_wakeup_granularity_ns" = 15000000; # 15ms
    "kernel.sched_migration_cost_ns" = 250000; # Good for quad-core
    "kernel.nmi_watchdog" = 0;  # Disable NMI watchdog for better performance
    
    # File System improvements
    "fs.inotify.max_user_watches" = 524288;
    "fs.file-max" = 2097152;
  };
  
  # Enable zram for better memory management without swap file
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25; # Use 25% of RAM for compressed swap
  };
  
  # Enable nix-command and nix-index for better UX
  programs.nix-index.enable = true;
  programs.command-not-found.enable = false; # Replaced by nix-index

  # Enhanced security settings with gaming optimizations
  security = {
    sudo.enable = true;
    polkit.enable = true;
    protectKernelImage = true;
    
    # Adjust PAM limits for gaming
    pam.loginLimits = [
      {
        domain = "*";
        type = "soft";
        item = "nofile";
        value = "524288";
      }
      {
        domain = "*"; 
        type = "hard";
        item = "nofile";
        value = "524288";
      }
    ];
  };

  # System-wide environment variables
  environment.variables = {
    # Default applications
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "alacritty";
    BROWSER = "firefox";
    
    # Wayland-specific environment variables
    MOZ_ENABLE_WAYLAND = "1";
    QT_QPA_PLATFORM = "wayland";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    GDK_BACKEND = "wayland";
    SDL_VIDEODRIVER = "wayland";
    _JAVA_AWT_WM_NONREPARENTING = "1";
    XDG_CURRENT_DESKTOP = "Hyprland";
    XDG_SESSION_TYPE = "wayland";
    XDG_SESSION_DESKTOP = "Hyprland";
    WLR_NO_HARDWARE_CURSORS = "1"; # Fix for some VM environments
    
    # AMD RX 6650XT and Mesa optimizations
    RADV_PERFTEST = "aco";          # Enable ACO compiler for better shader performance
    mesa_glthread = "true";         # Enable threading in Mesa
    __GL_THREADED_OPTIMIZATIONS = "1"; # Better OpenGL performance
    vblank_mode = "0";              # Disable waiting for vertical refresh when testing performance
  };

  # Enable common services
  services = {
    # Enable CUPS for printing
    printing = {
      enable = true;
      drivers = [ pkgs.gutenprint ];
    };
    
    # Enable the OpenSSH daemon
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
    
    # Add preload for faster application launch
    preload = {
      enable = true;
    };
    
    # Audio settings
    pulseaudio.enable = false; # Disable PulseAudio in favor of PipeWire
  };
  
  # Enhanced PipeWire for gaming and desktop audio performance
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true; # For 32-bit games with audio
    pulse.enable = true; # PulseAudio compatibility
    jack.enable = true; # JACK compatibility
    
    # Audio configuration for lower latency
    extraConfig.pipewire = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 44100 48000 96000 ];
        "default.clock.quantum" = 256;  # Lower for less latency
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 8192;
      };
    };
  };

  # Enable automatic system updates
  system.autoUpgrade = {
    enable = true;
    allowReboot = false; # Set to true if you want automatic reboots
    flake = "github:tuhoiisa/nixos-config"; # Change to your GitHub repo once pushed
    flags = [
      "--update-input" "nixpkgs"
      "--commit-lock-file"
    ];
    dates = "daily"; # Run updates daily
  };
}
