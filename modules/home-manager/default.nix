{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ./hyprland.nix
    ./neovim.nix
  ];

  # Home Manager configuration
  home = {
    packages = with pkgs; [
      # Terminal utilities
      alacritty
      zsh
      oh-my-zsh
      starship
      eza  # Modern replacement for 'exa'
      bat
      fd
      ripgrep
      fzf
      jq
      
      # File management
      ranger
      
      # Internet
      firefox
      
      # Network tools (useful with dnsproxy)
      dnsutils
      traceroute
      inetutils
      wget
      curl
      
      # System monitoring
      btop
      
      # AMD GPU monitoring and control tools
      radeontop      # Monitor AMD GPU usage
      corectrl       # AMD GPU control (drivers already enabled at system level)
      nvtopPackages.amd  # GPU process monitoring for AMD
      
      # Screenshots
      grim
      slurp
      
      # Notification daemon
      mako
      
      # Wallpaper
      swaybg
      
      # Application launcher
      rofi-wayland
      
      # Audio control
      pavucontrol
      
      # Status bar
      waybar
      
      # Clipboard manager
      wl-clipboard
      
      # File manager
      pcmanfm
      
      # Utilities
      brightnessctl
      
      # Development
      vscode
      git
      
      # Gaming utilities
      mangohud        # Gaming overlay
      gamescope       # Valve's display compositor for gaming
      
      # Discord with secure DNS
      vesktop  # The base Vesktop package
      
      # Custom Vesktop launcher with DNS proxy settings
      (writeShellScriptBin "vesktop-secure" ''
        #!/bin/sh
        # This wrapper uses DNSProxy to bypass restrictions for Discord
        # It only affects Vesktop and not the entire system
        
        # Configuration for Proxychains
        PROXYCHAINS_CONF=$(mktemp)
        cat > $PROXYCHAINS_CONF << EOF
        # Custom proxychains.conf for Vesktop
        strict_chain
        quiet_mode
        proxy_dns
        
        [ProxyList]
        # Use local DNSProxy for DNS resolution
        dns 127.0.0.1 5354
        EOF
        
        # Run Vesktop with proxychains for DNS resolution
        echo "Starting Vesktop with secure DNS configuration..."
        ${proxychains}/bin/proxychains4 -f $PROXYCHAINS_CONF ${vesktop}/bin/vesktop "$@"
        
        # Clean up
        rm -f $PROXYCHAINS_CONF
      '')
      
      # Create a desktop entry for secure Vesktop
      (makeDesktopItem {
        name = "vesktop-secure";
        desktopName = "Vesktop (Secure)";
        exec = "vesktop-secure %U";
        icon = "vesktop";
        comment = "Discord client with Vencord with secure DNS";
        categories = [ "Network" "InstantMessaging" ];
        mimeTypes = [ "x-scheme-handler/discord" ];
      })
    ];
    
    # Basic session variables with gaming optimizations
    sessionVariables = {
      EDITOR = "nvim";
      TERMINAL = "alacritty";
      BROWSER = "firefox";
      
      # Gaming optimizations for Wine/Proton
      DXVK_ASYNC = "1";                      # Enable async shader compilation
      WINE_FULLSCREEN_FSR = "1";             # FidelityFX Super Resolution in fullscreen
      WINE_FULLSCREEN_FSR_STRENGTH = "2";    # FSR sharpness (0-5, 2 is balanced)
      MANGOHUD = "1";                        # Enable MangoHud by default
      MANGOHUD_CONFIG = "cpu_temp,gpu_temp,vram,ram,position=top-left,height=500,font_size=22";
      
      # Steam-specific optimizations
      STEAM_RUNTIME_PREFER_HOST_LIBRARIES = "1";  # Use system libraries when possible
      PROTON_HIDE_NVIDIA_GPU = "0";          # Do not hide NVIDIA GPU (for AMD)
      PROTON_ENABLE_NVAPI = "0";             # Disable NVIDIA API on AMD
      PROTON_FORCE_LARGE_ADDRESS_AWARE = "1"; # Allow 32-bit games to use >2GB RAM
    };
  };

  # XDG configuration
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
    mimeApps = {
      enable = true;
    };
  };

  # Programs configuration
  programs = {
    home-manager.enable = true;
    
    # Terminal
    alacritty = {
      enable = true;
      settings = {
        font = {
          normal.family = "JetBrainsMono Nerd Font";
          size = 11;
        };
        window.opacity = 0.95;
      };
    };
    
    # Shell
    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      enableCompletion = true;
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" "sudo" "docker" "fzf" ];
        theme = "robbyrussell";
      };
      initContent = ''
        # Custom zsh configurations
        bindkey -e
        setopt AUTO_CD
        setopt HIST_IGNORE_DUPS
      '';
    };
    
    # Prompt
    starship = {
      enable = true;
      settings = {
        add_newline = true;
        character = {
          success_symbol = "[➜](bold green)";
          error_symbol = "[✗](bold red)";
        };
      };
    };
    
    # Git
    git = {
      enable = true;
      userName = "tuhoiisa";
      userEmail = "tuhoiisa@example.com";
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = false;
      };
    };
    
    # Firefox
    firefox = {
      enable = true;
      profiles.default = {
        id = 0;
        settings = {
          "browser.startup.homepage" = "https://nixos.org";
        };
      };
    };
    
    # Direnv - for per-project environment variables
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    
    # Removed fontconfig from here as it should be at home level
  };

  # Ensure services are configured
  services = {
    # Screen locker
    swayidle = {
      enable = true;
      timeouts = [
        { 
          timeout = 300;
          command = "${pkgs.swaylock}/bin/swaylock -f -c 000000";
        }
        {
          timeout = 600;
          command = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
    };
  };

  # GTK theme settings
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    font = {
      name = "Noto Sans";
      size = 11;
    };
  };

  # Qt theme settings
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };
}
