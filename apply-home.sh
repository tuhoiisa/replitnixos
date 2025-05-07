#!/bin/bash

# Script to apply the home-manager configuration to the current user

echo "Applying home-manager configuration for user $(whoami)..."

# Make sure we're not running as root
if [ "$EUID" -eq 0 ]; then
  echo "Error: This script should not be run as root, but as the normal user"
  exit 1
fi

# Check if home-manager is installed
if ! command -v home-manager &> /dev/null; then
  echo "Error: home-manager is not installed or not in PATH"
  echo "Please install home-manager first: https://nix-community.github.io/home-manager/index.html#sec-install-standalone"
  exit 1
fi

# Build and switch to the new home configuration
echo "Building and switching to new home-manager configuration..."
home-manager switch --flake .#tuhoiisa

if [ $? -eq 0 ]; then
  echo "✅ Home configuration applied successfully!"
else
  echo "❌ Error applying home configuration"
  exit 1
fi