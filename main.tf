terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.135.0"
    }
  }
  required_version = ">= 0.13"
}

variable "zone" {
  type        = string
  description = "Cloud zone"
}

variable "cloud-id" {
  type        = string
  description = "Cloud id"
}

variable "folder-id" {
  type        = string
  description = "Folder id"
}

provider "yandex" {
  service_account_key_file = pathexpand("~/keys/yc-key.json")
  cloud_id                 = var.cloud-id
  folder_id                = var.folder-id
  zone                     = var.zone
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts-oslogin"
}

resource "yandex_compute_disk" "boot-disk" {
  name     = "vvot22-boot-disk"
  type     = "network-ssd"
  image_id = data.yandex_compute_image.ubuntu.id
  size     = 20 
}

resource "yandex_compute_instance" "server" {
  name        = "vvot22-server-nextcloud"
  platform_id = "standard-v3"
  hostname    = "nextcloud"

  resources {
    core_fraction = 20
    cores         = 2
    memory        = 4
  }

  boot_disk {
    disk_id = yandex_compute_disk.boot-disk.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

resource "yandex_vpc_network" "network" {
  name = "vvot22-nextcloud-network"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "vvot22-nextcloud-subnet"
  zone           = var.zone
  v4_cidr_blocks = ["192.168.10.0/24"]
  network_id     = yandex_vpc_network.network.id
}
