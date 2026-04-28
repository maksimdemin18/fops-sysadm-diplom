resource "yandex_compute_instance" "bastion" {
  name        = "bastion"
  hostname    = "bastion"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  labels      = merge(var.labels, { role = "bastion" })

  resources {
    cores  = var.service_resources.bastion_cores
    memory = var.service_resources.bastion_memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.service_resources.bastion_disk
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion.id]
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }
}

resource "yandex_compute_instance" "web1" {
  name        = "web-1"
  hostname    = "web-1"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  labels      = merge(var.labels, { role = "web", az = "a" })

  resources {
    cores  = var.web_resources.cores
    memory = var.web_resources.memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.web_resources.disk
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web.id]
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }
}

resource "yandex_compute_instance" "web2" {
  name        = "web-2"
  hostname    = "web-2"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"
  labels      = merge(var.labels, { role = "web", az = "b" })

  resources {
    cores  = var.web_resources.cores
    memory = var.web_resources.memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.web_resources.disk
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_b.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.web.id]
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }
}

resource "yandex_compute_instance" "prometheus" {
  name        = "prometheus"
  hostname    = "prometheus"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  labels      = merge(var.labels, { role = "prometheus" })

  resources {
    cores  = var.service_resources.prometheus_cores
    memory = var.service_resources.prometheus_memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.service_resources.prometheus_disk
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.prometheus.id]
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }
}

resource "yandex_compute_instance" "elasticsearch" {
  name        = "elasticsearch"
  hostname    = "elasticsearch"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  labels      = merge(var.labels, { role = "elasticsearch" })

  resources {
    cores  = var.service_resources.elastic_cores
    memory = var.service_resources.elastic_memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.service_resources.elastic_disk
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private_a.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.elasticsearch.id]
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }
}

resource "yandex_compute_instance" "grafana" {
  name        = "grafana"
  hostname    = "grafana"
  platform_id = "standard-v3"
  zone        = "ru-central1-a"
  labels      = merge(var.labels, { role = "grafana" })

  resources {
    cores  = var.service_resources.grafana_cores
    memory = var.service_resources.grafana_memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.service_resources.grafana_disk
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_a.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.grafana.id]
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }
}

resource "yandex_compute_instance" "kibana" {
  name        = "kibana"
  hostname    = "kibana"
  platform_id = "standard-v3"
  zone        = "ru-central1-b"
  labels      = merge(var.labels, { role = "kibana" })

  resources {
    cores  = var.service_resources.kibana_cores
    memory = var.service_resources.kibana_memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.service_resources.kibana_disk
      type     = "network-ssd"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public_b.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.kibana.id]
  }

  metadata = {
    ssh-keys = local.ssh_keys
  }
}
