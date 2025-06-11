// packer_rocky9.pkr.hcl

packer {
  required_plugins {
    virtualbox = {
      source  = "github.com/hashicorp/virtualbox"
      version = "~> 1" # Use a compatible version for the VirtualBox plugin
    }
  }
}

// Define variables
variable "iso_checksum" {
  type        = string
  description = "SHA256 checksum of the ISO file"
  default     = "eedbdc2875c32c7f00e70fc861edef48587c7cbfd106885af80bdf434543820b" // Replace with the actual SHA256 checksum of your Rocky-9.5-x86_64-minimal.iso
}

variable "iso_url" {
  type        = string
  description = "Path to the ISO file"
  default     = "C:\\Users\\devops\\Downloads\\OS\\Rocky-9.5-x86_64-minimal.iso"
}

variable "vm_name" {
  type        = string
  description = "Name of the VirtualBox VM"
  default     = "rocky9-packer-vm"
}

variable "disk_size" {
  type        = string
  description = "Size of the virtual disk in MB"
  default     = "40960" // 40 GB
}

variable "memory" {
  type        = string
  description = "Memory allocated to the VM in MB"
  default     = "2048" // 2 GB
}

variable "cpus" {
  type        = string
  description = "Number of CPUs allocated to the VM"
  default     = "2"
}

variable "version" {
  type        = string
  description = "Version for the Vagrant box"
  default     = "1.0.0" # Default version if not specified on the command line
}


// Source block for VirtualBox
source "virtualbox-iso" "rocky9" {
  // Required ISO settings
  iso_url           = var.iso_url
  iso_checksum      = "sha256:${var.iso_checksum}"
  guest_os_type     = "RedHat_64" // Specify the guest OS type for VirtualBox

  // VM configuration
  vm_name           = var.vm_name
  disk_size         = var.disk_size
  memory            = var.memory
  cpus              = var.cpus
  headless          = true // Run VirtualBox in headless mode (no GUI)

  // Boot configuration
  boot_wait         = "15s"
  boot_command      = [
    "<tab> ip=dhcp net.ifnames=0 biosdevname=0 inst.text nomodeset inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter>" // Added 'inst.text' for text mode installer and 'nomodeset' for display issues
  ]

  // SSH configuration
  ssh_username      = "packer"
  ssh_password      = "packer"
  ssh_port          = 22
  ssh_timeout       = "20m"

  // Guest additions
  guest_additions_mode = "upload" // Upload Guest Additions ISO

  // Output directory
  output_directory  = "output-rocky9-virtualbox"

  // HTTP server for kickstart file
  http_directory    = "http"

  // Graceful shutdown command for the VM
  shutdown_command = "sudo shutdown -P now"
}

// Build block
build {
  sources = ["source.virtualbox-iso.rocky9"]

  // Provisioners to run commands inside the VM
  provisioner "shell" {
    inline = [
      "sudo dnf update -y",
      "sudo dnf install -y open-vm-tools", // or open-vm-tools-desktop if GUI
      "sudo systemctl enable --now vmtoolsd",
      "sudo dnf clean all",
      "sudo rm -rf /tmp/*",
      "sudo rm -f /var/log/messages /var/log/audit/audit.log",
      "sudo rm -f /root/.bash_history",
      "sudo rm -f /home/packer/.bash_history",
      "sudo sync",
      "sudo reboot" // Power off the VM gracefully after provisioning
    ]
    expect_disconnect = true # Added: Expect temporary SSH disconnection during these operations
  }

  provisioner "shell" {
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E {{ .Path }}"
    script          = "scripts/setup.sh" // Path to the setup script
    expect_disconnect = true # Tell Packer to expect the SSH connection to drop and try to reconnect
  }

  post-processor "vagrant" {
    output = "rocky9-minimal-${var.version}.box" 
    # This ensures the box is VirtualBox-specific
    compression_level = 9 # Optional: Set compression level (0-9, 9 is highest)
  }
}
