# This is a placeholder hardware configuration file.
# In a real system, this would be generated using 'nixos-generate-config'
# and contain the specific hardware setup for your machine.

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Example configuration - adjust according to your actual hardware
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # File systems configuration
  # This is just a placeholder - you would replace this with your actual partitioning scheme
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # Swap configuration
  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  # Hardware settings for Intel CPU as an example
  # Replace with AMD settings if necessary
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Power management - using performance for gaming
  # This is overridden in the main configuration to "performance"
  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}
