data "yandex_compute_image" "ubuntu" {
  family = var.image_family
}

locals {
  ssh_keys = "${var.vm_user}:${file(var.ssh_public_key_path)}"
}

resource "yandex_vpc_network" "main" {
  name   = var.network_name
  labels = var.labels
}

resource "yandex_vpc_gateway" "nat_gateway" {
  name = "coursework-nat-gateway"
  labels = merge(var.labels, {
    role = "nat-gateway"
  })
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private_rt" {
  name       = "coursework-private-rt"
  network_id = yandex_vpc_network.main.id
  labels     = var.labels

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

resource "yandex_vpc_subnet" "public_a" {
  name           = "public-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.cidr_blocks.public_a]
  labels         = merge(var.labels, { tier = "public", az = "a" })
}

resource "yandex_vpc_subnet" "public_b" {
  name           = "public-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.cidr_blocks.public_b]
  labels         = merge(var.labels, { tier = "public", az = "b" })
}

resource "yandex_vpc_subnet" "private_a" {
  name           = "private-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.cidr_blocks.private_a]
  route_table_id = yandex_vpc_route_table.private_rt.id
  labels         = merge(var.labels, { tier = "private", az = "a" })
}

resource "yandex_vpc_subnet" "private_b" {
  name           = "private-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.cidr_blocks.private_b]
  route_table_id = yandex_vpc_route_table.private_rt.id
  labels         = merge(var.labels, { tier = "private", az = "b" })
}
