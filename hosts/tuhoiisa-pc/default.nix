{ config, pkgs, inputs, lib, ... }:

{
  # Allow unfree packages like VS Code
  nixpkgs.config.allowUnfree = true;
  imports = [
    # Include hardware configuration for the machine
    ./hardware-configuration.nix
  ];

  # Set up bootloader - using systemd-boot as an example
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Optimized networking for gaming
  networking = {
    networkmanager = {
      enable = true;
      # Optimizations for lower latency
      wifi.powersave = false;
      # Use systemd-resolved for DNS
      dns = "none";
    };
    
    # Fast, privacy-focused DNS servers
    nameservers = [ "1.1.1.1" "9.9.9.9" ];
    
    # Firewall optimization for gaming
    firewall = {
      enable = true;
      allowPing = true;
      # Enable connection tracking for better online gaming
      connectionTrackingModules = [ "ftp" "irc" "sane" "sip" "tftp" ];
      # Allow DNSProxy port for local use
      allowedTCPPorts = [ 5354 ];
      allowedUDPPorts = [ 5354 ];
    };
  };

  # DNSProxy for Discord access (not system-wide)
  services.dnsproxy = {
    enable = true;
    settings = {
      listen-addrs = [ "127.0.0.1" ];
      listen-ports = [ 5354 ]; # Using a non-standard port
      bootstrap-dns = "1.1.1.1:53";
      upstream = [
        "https://dns.cloudflare.com/dns-query"
        "https://dns.google/dns-query"
      ];
      cache = true;
      insecure = false; # Keep connections secure
    };
  };
  
  # Additional networking tools for censorship circumvention
  networking.wireguard.enable = true;

  # Set your time zone
  time.timeZone = "UTC";

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
  };

  # Enable sound through rtkit (pipewire is configured in modules/nixos/default.nix)
  security.rtkit.enable = true;

  # Graphics configuration for AMD RX 6650XT
  hardware = {
    # AMD-specific optimizations for RX 6650XT - Using new option names
    graphics = {
      enable = true;
      # AMD-specific packages
      extraPackages = with pkgs; [
        amdvlk   # AMD Vulkan drivers
        rocmPackages.clr   # ROCm OpenCL Runtime
      ];
      extraPackages32 = with pkgs.driversi686Linux; [
        amdvlk # 32-bit support for games
      ];
    };
    
    # Enable Intel microcode updates for i3-13100F
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  # Enable Hyprland
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  
  # Enhanced XDG portal support for gaming and screen sharing
  xdg.portal = {
    enable = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  # Configure X11 for compatibility 
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = true;
  };

  # Define user account
  users.users.tuhoiisa = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.zsh;
  };

  # System packages
  environment.systemPackages = with pkgs; [
    # Basic utilities
    wget
    curl
    git
    killall
    pciutils
    usbutils
    file
    
    # Networking and anti-censorship tools
    openresolv        # For DNS management
    proxychains
    nmap
    wireguard-tools
    dnsproxy
    inetutils
    dnsutils
    
    # Text editors
    neovim
    
    # System tools
    htop
    btop
    
    # Compression tools
    zip
    unzip
    
    # Development tools
    gnumake
    gcc
    
    # Graphics and GPU tools for AMD RX 6650XT
    vulkan-tools        # Vulkan utilities
    vulkan-loader       # Vulkan runtime
    vulkan-validation-layers  # Vulkan development
    libva-utils         # Video acceleration tools
    vaapiVdpau          # VDPAU backend for VA-API
    libva               # Video Acceleration API
    libvdpau            # Video Decode and Presentation API
    radeontop           # Monitor AMD GPU usage
    clinfo              # Check OpenCL configuration
    glxinfo             # OpenGL information
    
    # Gaming utilities
    mangohud            # In-game overlay for monitoring
    gamemode            # Optimize system for gaming
  ];

  # Enable zsh
  programs.zsh.enable = true;

  # Enable dconf (needed for GTK theme settings)
  programs.dconf.enable = true;
  
  # Gaming and GPU management programs
  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      
      # Use Steam's built-in compatibility packages
      # This includes Proton by default
    };
    
    # For AMD GPU overclocking/monitoring
    corectrl.enable = true; # AMD GPU control tool
    
    # Game Mode daemon for optimizing CPU and GPU during gameplay
    gamemode = {
      enable = true;
      settings = {
        general = {
          renice = 10;  # Priority boost for games
          inhibit_screensaver = 1;  # Prevent screensaver during gaming
        };
        gpu = {
          apply_gpu_optimisations = 1;
          gpu_device = 0;  # First GPU (your AMD RX 6650XT)
          amd_performance_level = "high";  # Set AMD GPU to high performance during gaming
        };
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
        };
      };
    };
  };
  
  # Additional gaming services
  services = {
    # Improved scheduling for CPU resources
    ananicy = {
      enable = true;
      # Using default ananicy package
    };
    
    # Automatically fix shared libraries for games
    # Makes incompatible libraries usable by games
    nscd.enable = true;  # Name service cache daemon for better gaming
    
    # Enable AI-powered application recommendation engine
    app-recommender = {
      enable = true;
      scanInterval = 7;  # Scan weekly for new recommendations
    };
  };

  # Enable fonts
  fonts = {
    packages = with pkgs; [
      # Base fonts
      noto-fonts
      noto-fonts-cjk-sans  # Updated from noto-fonts-cjk
      noto-fonts-emoji
      liberation_ttf
      
      # Programming fonts with ligatures
      fira-code
      fira-code-symbols
      jetbrains-mono
      
      # Nerd fonts (patched with icons)
      nerd-fonts.fira-code
      nerd-fonts.jetbrains-mono
      nerd-fonts.hack
      nerd-fonts.sauce-code-pro  # Correct name for Source Code Pro
      
      # Beautiful UI fonts
      ubuntu_font_family
      roboto
      inter
      open-sans
      lato
      
      # Additional fonts
      mplus-outline-fonts.githubRelease
      dina-font
      proggyfonts
      font-awesome
      material-icons
      material-design-icons
    ];
    
    # Font configuration
    fontconfig = {
      # Updated naming convention for font defaults
      defaultFonts = {
        serif = [ "Noto Serif" "Ubuntu" ];
        sansSerif = [ "Inter" "Roboto" "Noto Sans" ];
        monospace = [ "JetBrainsMono Nerd Font" "FiraCode Nerd Font" ];
        emoji = [ "Noto Color Emoji" ];
      };
      # Enable sub-pixel RGB rendering
      subpixel.rgba = "rgb";
    };
  };

  # Desktop-optimized power management
  services.power-profiles-daemon.enable = true;
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance"; # Use performance for desktop system
    powertop.enable = false; # Not needed for desktop
  };
  
  # SSD and filesystem optimizations for gaming
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
  
  # Performance filesystem options for gaming
  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ];
  
  # Thermal management (still useful for desktop)
  services.thermald.enable = true;
  
  # Disk I/O scheduling optimization for better gaming performance
  services.udev.extraRules = ''
    # Set I/O scheduler to improve SSD performance
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/scheduler}="mq-deadline"
    ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
  '';
  
  # Performance-optimized kernel configuration for Intel i3-13100F and AMD RX 6650XT
  boot = {
    # Use latest kernel for best hardware support
    kernelPackages = pkgs.linuxPackages_latest;
    
    # Performance kernel parameters
    kernelParams = [
      # Scheduler options
      "sched_latency_ns=4000000" # Reduced latency (4ms) for desktop responsiveness
      "migration_cost_ns=250000" # Better for i3-13100F quad-core
      
      # AMD GPU specific options
      "amdgpu.ppfeaturemask=0xffffffff" # Enable all amdgpu power features
      "radeon.si_support=0" # Disable Southern Islands support for newer cards
      "radeon.cik_support=0" # Disable Sea Islands support for newer cards
      "amdgpu.si_support=1" # Enable Southern Islands support in amdgpu
      "amdgpu.cik_support=1" # Enable Sea Islands support in amdgpu
      "amd_iommu=on" # Enable IOMMU for better performance
      
      # Gaming and responsiveness options
      "nowatchdog" # Disable the watchdog timer
      "quiet" # Limit kernel output while booting
      "mitigations=off" # Disable CPU Mitigations (security risk but better performance)
      "tsc=reliable" # Assume Time Stamp Counter is reliable
      "threadirqs" # Thread IRQs for better latency
      
      # I/O scheduler
      "elevator=kyber" # Better for SSD and gaming
    ];
    
    # Configure kernel options to optimize for gaming
    # Using lib.mkForce to override the defaults in modules/nixos/default.nix
    kernel.sysctl = {
      # Gaming optimizations - reduce IO impact on CPU
      "vm.dirty_ratio" = lib.mkForce 6; 
      "vm.dirty_background_ratio" = lib.mkForce 3;
      "vm.swappiness" = lib.mkForce 5;
    };
    
    # Performance optimizations are centralized in modules/nixos/default.nix
  };
  
  # System state version
  system.stateVersion = "23.11";
}
