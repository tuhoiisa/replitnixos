#!/bin/bash

# Script to apply the NixOS configuration to the local system

echo "Applying NixOS system configuration..."

# Check if running as sudo/root
if [ "$EUID" -ne 0 ]; then
  echo "Error: This script must be run as root (with sudo)"
  exit 1
fi

# Build and switch to the new configuration
echo "Building and switching to new NixOS configuration..."
nixos-rebuild switch --flake .#tuhoiisa-pc

if [ $? -eq 0 ]; then
  echo "✅ System configuration applied successfully!"
else
  echo "❌ Error applying system configuration"
  exit 1
fi