# NixOS Configuration for tuhoiisa-pc

This repository contains a complete NixOS system configuration with home-manager, Hyprland window manager, and Neovim for user 'tuhoiisa' on host 'tuhoiisa-pc'.

## Overview

The configuration is organized as a Nix flake, which makes it reproducible and easy to manage. It includes:

- NixOS system configuration
- Home Manager for user environment management
- Hyprland Wayland compositor for a modern desktop experience
- Neovim configured as a powerful code editor

## Structure

```
.
├── hosts/                        # Host-specific configurations
│   └── tuhoiisa-pc/              # Configuration for tuhoiisa-pc
│       ├── default.nix           # Main system configuration
│       └── hardware-configuration.nix  # Hardware-specific settings
├── modules/                      # Shared configuration modules
│   ├── home-manager/             # Home Manager modules
│   │   ├── default.nix           # Main Home Manager configuration
│   │   ├── hyprland.nix          # Hyprland window manager configuration
│   │   └── neovim.nix            # Neovim editor configuration
│   └── nixos/                    # NixOS modules
│       └── default.nix           # Shared NixOS configuration
└── flake.nix                     # Flake entry point
```

## Features

### CachyOS Kernel

This configuration includes the CachyOS kernel from the [drakon64/nixos-cachyos-kernel](https://github.com/drakon64/nixos-cachyos-kernel) repository, an optimized Linux kernel with the following features:
- Uses the TkG kernel patches for improved desktop performance
- Advanced scheduler tuning for better responsiveness
- Custom process scheduling latency settings
- Optimized task migration for better thread handling
- Highly tweaked for gaming and desktop workloads
- Disabled CPU mitigations for maximum performance (with security trade-offs)
- Thread IRQs for better latency in real-time applications


### System Configuration

- Latest NixOS unstable channel
- Optimized for desktop usage
- Configured with modern audio (PipeWire)
- Support for hardware acceleration

### Hyprland Configuration

- Modern Wayland compositor with animations
- Configured for productivity with workspace management
- Customized hotkeys for efficient window management
- Integration with status bar (Waybar) and notification system (Mako)

### Neovim Configuration

- Full IDE-like experience with LSP integration
- Language servers for Nix, Python, TypeScript, Bash, and Lua
- Code completion with nvim-cmp
- Fuzzy finding with Telescope
- File navigation with nvim-tree
- Git integration

## Usage

On a NixOS system, you can use this configuration by:

1. Clone this repository to your local machine
2. Make the helper scripts executable:
   ```
   chmod +x apply-system.sh apply-home.sh
   ```
3. Apply the full system configuration (requires root):
   ```
   sudo ./apply-system.sh
   ```

To update your user environment only, you can run:
```
./apply-home.sh
```

### Manual Application

If you prefer to run the commands manually:

- To build and switch to the new system configuration:
  ```
  sudo nixos-rebuild switch --flake .#tuhoiisa-pc
  ```

- To build and switch to the new home-manager configuration:
  ```
  home-manager switch --flake .#tuhoiisa
  ```

## Customization

### Basic Customization

To adapt this configuration for your own use:

1. Change the username and hostname in `flake.nix`
2. Modify the hardware configuration in `hosts/your-hostname/hardware-configuration.nix`
3. Adjust system settings in `hosts/your-hostname/default.nix`
4. Customize user configuration in the `modules/home-manager` directory

### Advanced Customization

#### Adding a New Host

1. Create a new directory under `hosts/` with your hostname
2. Create `default.nix` and `hardware-configuration.nix` in this directory
3. Add the new host to `flake.nix` in the `nixosConfigurations` section:
   ```nix
   nixosConfigurations = {
     tuhoiisa-pc = mkHost "tuhoiisa-pc";
     your-hostname = mkHost "your-hostname";
   };
   ```

#### Adding More Users

1. Add the new user to your host configuration in `hosts/your-hostname/default.nix`
2. Create a new home-manager configuration in `flake.nix`:
   ```nix
   homeConfigurations = {
     tuhoiisa = mkHome "tuhoiisa";
     newuser = mkHome "newuser";
   };
   ```
3. Add the user to the home-manager section of your host:
   ```nix
   home-manager.users.newuser = import ./modules/home-manager;
   ```

#### Adding Custom Modules

1. Create a new module file in `modules/nixos/` or `modules/home-manager/`
2. Import it in the respective `default.nix`

#### Creating a Live ISO

You can create a bootable NixOS image with your configuration:

```bash
nix build .#nixosConfigurations.tuhoiisa-pc.config.system.build.isoImage
```

## Version Control with Git

### Pushing to GitHub

To manage this configuration with Git and push it to GitHub:

1. **Create a GitHub repository**:
   - Go to [GitHub](https://github.com/) and log in
   - Click the "+" icon in the top-right corner and select "New repository"
   - Name your repository (e.g., "nixos-config")
   - Add an optional description
   - Choose public or private visibility
   - Create repository without README, .gitignore, or license

2. **Initialize and push from your local machine**:
   ```bash
   # Initialize the repository
   git init
   
   # Add all files to staging
   git add .
   
   # Create the initial commit
   git commit -m "Initial commit: NixOS configuration"
   
   # Set the main branch (if not already set)
   git branch -M main
   
   # Add the GitHub repository as a remote
   git remote add origin https://github.com/YOUR_USERNAME/nixos-config.git
   
   # Push to GitHub
   git push -u origin main
   ```

3. **Clone on a different machine**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/nixos-config.git
   cd nixos-config
   ```

### Recommended Git Workflow

For maintaining your NixOS configuration over time:

1. **Make changes to your configuration locally**
2. **Test changes** with `sudo nixos-rebuild test --flake .#tuhoiisa-pc` 
3. **Commit working changes**:
   ```bash
   git add .
   git commit -m "Description of changes"
   ```
4. **Push to GitHub**:
   ```bash
   git push
   ```
5. **Pull on other machines**:
   ```bash
   git pull
   ```

## Troubleshooting

### Common Issues

1. **Flake Evaluation Errors**:
   - Make sure all imported files exist
   - Check for syntax errors in Nix files
   - Verify the flake inputs are accessible

2. **Hardware Issues**:
   - If hardware isn't detected properly, update the hardware-configuration.nix
   - For laptops, you might need additional modules for power management
   - GPU drivers might need additional configuration

3. **Hyprland Not Working**:
   - Ensure your system has proper GPU drivers installed
   - Check if Wayland is working properly
   - Try running from a TTY with `Hyprland` command directly

4. **Home Manager Issues**:
   - Check that home-manager is properly installed
   - Verify user permissions and paths
   - Look for conflicting configurations between system and home-manager

### Getting Help

- NixOS Wiki: https://nixos.wiki/
- NixOS Discourse: https://discourse.nixos.org/
- NixOS Matrix/IRC: #nixos on https://matrix.to/#/#nixos:nixos.org

## License

This configuration is provided as-is, free to use and modify as needed.