/* Uses Cloud-Init options from Proxmox 5.2 */
resource "proxmox_vm_qemu" "cloudinit-test" {
  name        = "tftest1.xyz.com"
  desc        = "tf description"
  target_node = "proxmox1-xx"

  clone = "ci-ubuntu-template"

  # The destination resource pool for the new VM
  pool = "pool0"

  storage = "local"
  cores   = 3
  sockets = 1
  memory  = 2560
  disk_gb = 4
  nic     = "virtio"
  bridge  = "vmbr0"

  ssh_user        = "root"
  ssh_private_key = <<EOF
-----BEGIN RSA PRIVATE KEY-----
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAtLXv2aQkFbQm4qzJ/5L4CvgyxE3OoT5avDV84ZwNbM/ZCI90
QW5gDIs5kIVyPH4X1lPK+OLMCxTGoAlnIbYmP7641hXhUlvvZMimCug35wEtIDQi
5PHkCtS+9Sxrv91Qc7SZCI+q3A3DVfXQbScH9BAb0V3aLibQ78IcrCxa5Gi/iOoL
3rjpC7u378Uu/8tloBibNZzNj+LkIEfHoB+YwB8nYC7k0Uj/0UWJ2+y9rrShREbC
ozrYwI1LSKJ7M5KrA5Fn+YBYJSb0s7sAW3jhR90a8RmkidlOf/FQgSD1PSW+sv5s
eKASRLxrKiknnSGhu+jO8tPwyJT19z4rWTDGZQIDAQABAoIBABjJ9FLon0KS6dqi
VTtHz9rBXUVsXvHjedLji3PvUjAg+uaftxTarTZLSuQ2SgteSKrP58HoapECkpSV
dZ48PFb2NKi5a6U+k0JB+/T3EeQQVz5ZqIe7XsrVkDRVmZpCI60bkvqHqqpxAOCj
zamLdx3Vr9sygqFeFb8t430CwJ0gPYYu3634+I3tGEddLAyYpZhcfUwjad3h2nAJ
ifSghNzJOivSChZRzRirpjO9PRiQKafGebV4Df8RD2Ec1SV6M89ugyolNBFgpkH6
rqkEoWdKDBS2lqmNpnVMfpPRbaxOnsZU6EwsWT9I+C1ExYziTdn+ajhXF1gKWnNm
piAugWkCgYEA/Zda1EJyXYzeQpA8fOszD1tNqxdfrrAzs2h2BOBhM+TNyebc1Zqn
gXAtkNU22huPp+hoIt88Pl+gib2y4ffte9EsdjJJJshRlZUmb+87eACoENSMC2nK
FhWJAlBbMfQVfGHso8Md5nEN1S9a1PrPyV8mSoG/5pBWt/k8RPIm0o8CgYEAtm1c
tF5Zm99Liovbv6RD/EFuHZrjBan8hbGcvQyPBjjUq2leMV/eDOrIYr8xywi2/kIu
M3G0lJgx/0YhtYeGKmxcyIatpbMJ5FALhN6749ds/AXPZUtytyoGPMEW0fyRgnmD
ujZfcmarWttIzbeuUIXfKH/ZN6KjbqLo2sK2wcsCgYEAgzJ1CW+/H2sr6iAZSz+b
0QwZqLSVChmbBey7clZrs59iYFyST+iNVMgmqtHEaR7tOZ9hkPkRf+uVcO21yHau
ZOqZKCVn9yqYGt1pX2vTxogAa4SrV5RJuxc1JP9RzwxKuWkoNqlRpNFEqNCxG5MP
QU16z/1EvRJb6x6E8d6d+z0CgYA/U4tg2XfF0ifI+m/YAM/Q2228PS4dozqTtmow
fhGQGV5J+pPGE/9jAIV7Md+5GVdcv+CF3yzOgF6qvM+q0lbSlzdGLOpOoO4IIXk+
MIuMthWRDvtFsIEr8BymLmkbj897OW9uzr0nW1iUe5a0QtTyAubKikb/NygAmfC3
L+x9LQKBgH2VJ3pkfiGONvCS21M8+SYf69nVZaad+tkwWx4Y9vNeJm5UGXxWsdIE
CRpkbEwQvvqtQZsv6socMs3AjIWO64fjeWhhx6Xa9c4/GCs85pXC24prpHq+gbWi
4vIuBBtp6nJaOFpTtAuCU5PMfeiFSWsgYALTI590oThpaBflw0nM
-----END RSA PRIVATE KEY-----%
-----END RSA PRIVATE KEY-----
EOF

  os_type   = "cloud-init"
  ipconfig0 = "ip=10.0.2.99/16,gw=10.0.2.2"

  sshkeys = <<EOF
ssh-rsa AABB3NzaC1kj...key1
ssh-rsa AABB3NzaC1kj...key2
EOF

  provisioner "remote-exec" {
    inline = [
      "ip a"
    ]
  }
}

/* Null resource that generates a cloud-config file per vm */
data "template_file" "user_data" {
  count    = var.vm_count
  template = file("${path.module}/files/user_data.cfg")
  vars     = {
    pubkey   = file(pathexpand("~/.ssh/id_rsa.pub"))
    hostname = "vm-${count.index}"
    fqdn     = "vm-${count.index}.${var.domain_name}"
  }
}
resource "local_file" "cloud_init_user_data_file" {
  count    = var.vm_count
  content  = data.template_file.user_data[count.index].rendered
  filename = "${path.module}/files/user_data_${count.index}.cfg"
}

resource "null_resource" "cloud_init_config_files" {
  count = var.vm_count
  connection {
    type     = "ssh"
    user     = "${var.pve_user}"
    password = "${var.pve_password}"
    host     = "${var.pve_host}"
  }

  provisioner "file" {
    source      = local_file.cloud_init_user_data_file[count.index].filename
    destination = "/var/lib/vz/snippets/user_data_vm-${count.index}.yml"
  }
}

/* Configure Cloud-Init User-Data with custom config file */
resource "proxmox_vm_qemu" "cloudinit-test" {
  depends_on = [
    null_resource.cloud_init_config_files,
  ]

  name        = "tftest1.xyz.com"
  desc        = "tf description"
  target_node = "proxmox1-xx"

  clone = "ci-ubuntu-template"

  # The destination resource pool for the new VM
  pool = "pool0"

  storage = "local"
  cores   = 3
  sockets = 1
  memory  = 2560
  disk_gb = 4
  nic     = "virtio"
  bridge  = "vmbr0"

  ssh_user        = "root"
  ssh_private_key = <<EOF
-----BEGIN RSA PRIVATE KEY-----
private ssh key root
-----END RSA PRIVATE KEY-----
EOF

  os_type   = "cloud-init"
  ipconfig0 = "ip=10.0.2.99/16,gw=10.0.2.2"

  /*
    sshkeys and other User-Data parameters are specified with a custom config file.
    In this example each VM has its own config file, previously generated and uploaded to
    the snippets folder in the local storage in the Proxmox VE server.
  */
  cicustom                = "user=local:snippets/user_data_vm-${count.index}.yml"
  /* Create the Cloud-Init drive on the "local-lvm" storage */
  cloudinit_cdrom_storage = "local-lvm"

  provisioner "remote-exec" {
    inline = [
      "ip a"
    ]
  }
}

/* Uses custom eth1 user-net SSH portforward */
resource "proxmox_vm_qemu" "preprovision-test" {
  name        = "tftest1.xyz.com"
  desc        = "tf description"
  target_node = "proxmox1-xx"

  clone = "terraform-ubuntu1404-template"

  # The destination resource pool for the new VM
  pool = "pool0"

  cores    = 3
  sockets  = 1
  # Same CPU as the Physical host, possible to add cpu flags
  # Ex: "host,flags=+md-clear;+pcid;+spec-ctrl;+ssbd;+pdpe1gb"
  cpu      = "host"
  numa     = false
  memory   = 2560
  scsihw   = "lsi"
  # Boot from hard disk (c), CD-ROM (d), network (n)
  boot     = "cdn"
  # It's possible to add this type of material and use it directly
  # Possible values are: network,disk,cpu,memory,usb
  hotplug  = "network,disk,usb"
  # Default boot disk
  bootdisk = "virtio0"
  # HA, you need to use a shared disk for this feature (ex: rbd)
  hastate  = ""

  #Display
  vga {
    type   = "std"
    #Between 4 and 512, ignored if type is defined to serial
    memory = 4
  }

  network {
    id    = 0
    model = "virtio"
  }
  network {
    id     = 1
    model  = "virtio"
    bridge = "vmbr1"
  }
  disk {
    id           = 0
    type         = "virtio"
    storage      = "local-lvm"
    storage_type = "lvm"
    size         = "4G"
    backup       = true
  }
  # Serial interface of type socket is used by xterm.js
  # You will need to configure your guest system before being able to use it
  serial {
    id   = 0
    type = "socket"
  }
  preprovision    = true
  ssh_forward_ip  = "10.0.0.1"
  ssh_user        = "terraform"
  ssh_private_key = <<EOF
-----BEGIN RSA PRIVATE KEY-----
private ssh key terraform
-----END RSA PRIVATE KEY-----
EOF

  os_type           = "ubuntu"
  os_network_config = <<EOF
auto eth0
iface eth0 inet dhcp
EOF

  connection {
    type        = "ssh"
    user        = self.ssh_user
    private_key = self.ssh_private_key
    host        = self.ssh_host
    port        = self.ssh_port
  }

  provisioner "remote-exec" {
    inline = [
      "ip a"
    ]
  }
}
