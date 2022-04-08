terraform {
  required_version = ">= 1.1.0"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">= 2.9.5"
    }
  }
}
provider "proxmox" {
    pm_proxy_server = "http://proxyurl:proxyport"
    pm_tls_insecure = true
    PM_API_TOKEN_ID="terraform-prov@pve"
    pm_api_url = "https://proxmox-server01.example.com:8006/api2/json"
    pm_password = "Meisam20"
    pm_user = "terraform-prov@pve"
    pm_api_token_id = "YLTkfaJM2QF4mg.atlasv1.5Xc9bR62TvNFkucklOGHauXkFMLGGZax6zcoRoc3yCx3AUHa3cLnGfae2FBxGOA3tP8"
    pm_otp = ""
}

resource "proxmox_vm_qemu" "pxe-example" {
    name                      = "pxe-example"
    desc                      = "A test VM for PXE boot mode."
# PXE option enables the network boot feature
    pxe                       = true
# unless your PXE installed system includes the Agent in the installed
# OS, do not use this, especially for PXE boot VMs
    agent                     = 0
    automatic_reboot          = true
    balloon                   = 0
    bios                      = "seabios"
# boot order MUST include network first, this is enforced in the Provider
    boot                      = "order=net0;scsi0"
    cores                     = 2
    cpu                       = "host"
    define_connection_info    = true
    force_create              = false
    hotplug                   = "network,disk,usb"
    kvm                       = true
    memory                    = 2048
    numa                      = false
    onboot                    = false
    oncreate                  = true
    os_type                   = "Linux 5.x - 2.6 Kernel"
    qemu_os                   = "l26"
    scsihw                    = "virtio-scsi-pci"
    sockets                   = 1
    tablet                    = true
    target_node               = "test"
    vcpus                     = 0

    disk {
        backup       = 0
        cache        = "none"
        discard      = "on"
        iothread     = 1
        mbps         = 0
        mbps_rd      = 0
        mbps_rd_max  = 0
        mbps_wr      = 0
        mbps_wr_max  = 0
        replicate    = 0
        size         = "32G"
        ssd          = 1
        storage      = "local-lvm"
        type         = "scsi"
    }

    network {
        bridge    = "vmbr0"
        firewall  = false
        link_down = false
        model     = "e1000"
    }
}
