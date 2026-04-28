resource "yandex_alb_target_group" "web" {
  name   = "coursework-web-target-group"
  labels = merge(var.labels, { role = "alb-target-group" })

  target {
    subnet_id  = yandex_vpc_subnet.private_a.id
    ip_address = yandex_compute_instance.web1.network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.private_b.id
    ip_address = yandex_compute_instance.web2.network_interface.0.ip_address
  }
}

resource "yandex_alb_backend_group" "web" {
  name   = "coursework-web-backend-group"
  labels = merge(var.labels, { role = "alb-backend-group" })

  http_backend {
    name             = "web-backend"
    weight           = 1
    port             = 80
    target_group_ids = [yandex_alb_target_group.web.id]

    load_balancing_config {
      panic_threshold = 50
    }

    healthcheck {
      timeout          = "3s"
      interval         = "5s"
      healthcheck_port = 80

      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "main" {
  name   = "coursework-http-router"
  labels = merge(var.labels, { role = "alb-http-router" })
}

resource "yandex_alb_virtual_host" "main" {
  name           = "coursework-vhost"
  http_router_id = yandex_alb_http_router.main.id
  route {
    name = "root-route"

    http_route {
      http_match {
        path {
          prefix = "/"
        }
      }

      http_route_action {
        backend_group_id = yandex_alb_backend_group.web.id
        timeout          = "10s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "main" {
  name               = "coursework-alb"
  network_id         = yandex_vpc_network.main.id
  security_group_ids = [yandex_vpc_security_group.alb.id]
  labels             = merge(var.labels, { role = "alb" })

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public_a.id
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.public_b.id
    }
  }

  auto_scale_policy {
    min_zone_size = 2
    max_size      = 4
  }

  listener {
    name = "http-listener"
    endpoint {
      ports = [80]
      address {
        external_ipv4_address {}
      }
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.main.id
      }
    }
  }
}
