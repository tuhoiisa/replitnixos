{ config, pkgs, inputs, lib, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    
    settings = {
      # Monitor setup optimized for AMD RX 6650XT
      monitor = [
        # Main Display - Use high refresh rate if available
        "DP-1,preferred,auto,1,vrr,1" # Primary DisplayPort with adaptive sync
        "HDMI-A-1,preferred,auto,1"   # HDMI fallback
        ",preferred,auto,1"           # Catch-all for any other displays
      ];
      
      # GPU-specific performance tweaks
      xwayland = {
        force_zero_scaling = true;
      };

      # Execute these at launch
      exec-once = [
        "waybar"                                             # Status bar
        "mako"                                               # Notification daemon
        "swaybg -i ${pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath} --mode fill" # Wallpaper
      ];

      # General settings
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
        "col.inactive_border" = "rgba(595959aa)";
        layout = "dwindle";
      };

      # Decoration settings
      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          new_optimizations = true;
        };
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
        "col.shadow" = "rgba(1a1a1aee)";
      };

      # Animations
      animations = {
        enabled = true;
        bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
        animation = [
          "windows, 1, 7, myBezier"
          "windowsOut, 1, 7, default, popin 80%"
          "border, 1, 10, default"
          "fade, 1, 7, default"
          "workspaces, 1, 6, default"
        ];
      };

      # Input settings
      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = true;
        };
        sensitivity = 0;
      };

      # Layout settings
      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      # Miscellaneous settings - Optimized for AMD RX 6650XT
      misc = {
        force_default_wallpaper = 0;
        
        # Improved performance for AMD GPUs
        vfr = true;  # Variable refresh rate
        vrr = 1;     # Enable VRR (Adaptive Sync)
        
        # Gaming optimizations
        no_direct_scanout = false;  # Better for gaming
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = true;
        
        # Rendering optimization
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        
        # Use all cores for rendering
        render_ahead_of_time = true;
        render_ahead_safezone = 2;
      };

      # Window rules
      windowrule = [
        "float, ^(pavucontrol)$"
        "float, ^(nm-connection-editor)$"
        "float, ^(galculator)$"
      ];

      # Keybindings
      "$mod" = "SUPER";
      bind = [
        # Basic window management
        "$mod, Q, exec, alacritty"
        "$mod, C, killactive,"
        "$mod, M, exit,"
        "$mod, E, exec, pcmanfm"
        "$mod, V, togglefloating,"
        "$mod, P, pseudo,"    # dwindle
        "$mod, J, togglesplit," # dwindle
        "$mod, F, fullscreen, 0"

        # App launcher
        "$mod, R, exec, rofi -show drun"
        
        # Move focus
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        
        # Switch workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"
        
        # Move active window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
        
        # Scroll through workspaces
        "$mod, mouse_down, workspace, e+1"
        "$mod, mouse_up, workspace, e-1"
        
        # Screenshot
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
        "SHIFT, Print, exec, grim - | wl-copy"
        
        # Volume control
        ", XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%"
        ", XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%"
        ", XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle"
        
        # Brightness control
        ", XF86MonBrightnessUp, exec, brightnessctl set +5%"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Environment variables
      env = [
        "XCURSOR_SIZE,24"
        "QT_QPA_PLATFORM,wayland"
        "QT_QPA_PLATFORMTHEME,qt5ct"
        "MOZ_ENABLE_WAYLAND,1"
        "SDL_VIDEODRIVER,wayland"
        "GDK_BACKEND,wayland"
      ];
    };
  };

  # Configure Waybar for Hyprland
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = ["hyprland/workspaces" "hyprland/window"];
        modules-center = ["clock"];
        modules-right = ["pulseaudio" "network" "cpu" "memory" "tray"];
        
        "hyprland/workspaces" = {
          format = "{name}";
          on-click = "activate";
        };
        
        "clock" = {
          format = "{:%Y-%m-%d %H:%M}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
        
        "cpu" = {
          format = "CPU {usage}%";
          interval = 1;
        };
        
        "memory" = {
          format = "MEM {}%";
          interval = 1;
        };
        
        "network" = {
          format-wifi = "WIFI {signalStrength}%";
          format-ethernet = "ETH";
          format-linked = "ETH (No IP)";
          format-disconnected = "OFF";
          tooltip-format = "{ifname} ({essid})";
        };
        
        "pulseaudio" = {
          format = "VOL {volume}%";
          format-muted = "MUTED";
          on-click = "pavucontrol";
        };
        
        "tray" = {
          icon-size = 21;
          spacing = 10;
        };
      };
    };
    style = ''
      * {
        border: none;
        border-radius: 0;
        font-family: "JetBrainsMono Nerd Font";
        font-size: 14px;
        min-height: 0;
      }

      window#waybar {
        background: #1e1e2e;
        color: #cdd6f4;
      }

      #workspaces button {
        padding: 0 5px;
        color: #cdd6f4;
      }

      #workspaces button.active {
        background: #313244;
        border-bottom: 3px solid #cdd6f4;
      }

      #clock, #cpu, #memory, #network, #pulseaudio, #tray {
        padding: 0 10px;
      }
    '';
  };

  # Configure notification daemon
  services.mako = {
    enable = true;
    settings = {
      defaultTimeout = 5000;
      borderSize = 2;
      borderRadius = 5;
      backgroundColor = "#1e1e2e";
      textColor = "#cdd6f4";
      borderColor = "#89b4fa";
    };
  };
}
