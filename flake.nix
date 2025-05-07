{
  description = "NixOS configuration for tuhoiisa-pc";

  inputs = {
    # Core - Using the latest NixOS version for modern features
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # Home manager - Latest to match unstable channel
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    # Hyprland - Using a tested stable version
    hyprland = {
      url = "github:hyprwm/Hyprland/v0.33.1"; # Stable version that works with our configuration
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, hyprland, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
      
      # Function to create home-manager configuration
      mkHome = username: nixpkgs.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          ./modules/home-manager
          {
            home = {
              username = username;
              homeDirectory = "/home/${username}";
              stateVersion = "23.11";
            };
          }
        ];
      };
      
      # Function to build NixOS configuration for hosts
      mkHost = hostname: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/${hostname}
          ./modules/nixos
          home-manager.nixosModules.home-manager
          {
            networking.hostName = hostname;
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.tuhoiisa = { 
              imports = [ ./modules/home-manager ];
              home.stateVersion = "23.11";
            };
          }
        ];
      };
    in {
      homeConfigurations = {
        tuhoiisa = mkHome "tuhoiisa";
      };
      
      nixosConfigurations = {
        tuhoiisa-pc = mkHost "tuhoiisa-pc";
      };
    };
}
