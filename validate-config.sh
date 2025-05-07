#!/bin/bash

# A simple structural validation script for NixOS flake configuration
# This won't use nix commands but will check that the structure is correct

echo "Starting configuration validation..."
echo

# Check for the presence of core files
echo "Checking core files:"
files=(
  "flake.nix"
  "hosts/tuhoiisa-pc/default.nix"
  "hosts/tuhoiisa-pc/hardware-configuration.nix"
  "modules/nixos/default.nix"
  "modules/home-manager/default.nix"
  "modules/home-manager/hyprland.nix"
  "modules/home-manager/neovim.nix"
)

all_files_exist=true
for file in "${files[@]}"; do
  if [ -f "$file" ]; then
    echo "✅ $file exists"
  else
    echo "❌ $file is missing"
    all_files_exist=false
  fi
done

if $all_files_exist; then
  echo -e "\n✅ All required files exist"
else
  echo -e "\n❌ Some required files are missing"
  exit 1
fi

echo -e "\nChecking flake.nix structure:"
if grep -q "description.*tuhoiisa-pc" flake.nix; then
  echo "✅ flake.nix contains correct description"
else
  echo "❌ flake.nix missing or has incorrect description"
  exit 1
fi

if grep -q "nixpkgs\.url" flake.nix; then
  echo "✅ flake.nix contains nixpkgs input"
else
  echo "❌ flake.nix missing nixpkgs input"
  exit 1
fi

if grep -q "home-manager.*{" flake.nix; then
  echo "✅ flake.nix contains home-manager input"
else
  echo "❌ flake.nix missing home-manager input"
  exit 1
fi

if grep -q "hyprland.*{" flake.nix; then
  echo "✅ flake.nix contains hyprland input"
else
  echo "❌ flake.nix missing hyprland input"
  exit 1
fi

if grep -q "homeConfigurations.*{" flake.nix && grep -q "tuhoiisa.*=.*mkHome" flake.nix; then
  echo "✅ flake.nix defines tuhoiisa home configuration"
else
  echo "❌ flake.nix missing tuhoiisa home configuration"
  exit 1
fi

if grep -q "nixosConfigurations.*{" flake.nix && grep -q "tuhoiisa-pc.*=.*mkHost" flake.nix; then
  echo "✅ flake.nix defines tuhoiisa-pc system configuration"
else
  echo "❌ flake.nix missing tuhoiisa-pc system configuration"
  exit 1
fi

echo -e "\nChecking host configuration:"
if grep -q "users\.users\.tuhoiisa" hosts/tuhoiisa-pc/default.nix; then
  echo "✅ Host configuration defines user tuhoiisa"
else
  echo "❌ Host configuration missing user tuhoiisa"
  exit 1
fi

if grep -q "programs\.hyprland" hosts/tuhoiisa-pc/default.nix; then
  echo "✅ Host configuration enables hyprland"
else
  echo "❌ Host configuration not enabling hyprland"
  exit 1
fi

echo -e "\nChecking home-manager configuration:"
if grep -q "wayland\.windowManager\.hyprland" modules/home-manager/hyprland.nix; then
  echo "✅ Hyprland is configured in home-manager"
else
  echo "❌ Hyprland configuration in home-manager is missing or incorrect"
  exit 1
fi

if grep -q "programs\.neovim" modules/home-manager/neovim.nix; then
  echo "✅ Neovim is configured in home-manager"
else
  echo "❌ Neovim configuration in home-manager is missing or incorrect"
  exit 1
fi

echo -e "\n✅ Configuration validation complete - all checks passed!"
echo -e "\nNote: This script only validates the structure of the configuration."
echo "To fully validate the configuration, you would need to run 'nix flake check'"
echo "on a system with Nix and flakes support."