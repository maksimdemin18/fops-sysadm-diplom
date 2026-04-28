resource "yandex_vpc_security_group" "bastion" {
  name        = "sg-bastion"
  description = "SSH only for bastion"
  network_id  = yandex_vpc_network.main.id
  labels      = merge(var.labels, { role = "bastion" })

  ingress {
    protocol       = "TCP"
    description    = "SSH from Internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  egress {
    protocol       = "ANY"
    description    = "Any outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "alb" {
  name        = "sg-alb"
  description = "HTTP access to ALB"
  network_id  = yandex_vpc_network.main.id
  labels      = merge(var.labels, { role = "alb" })

  ingress {
    protocol       = "TCP"
    description    = "HTTP from Internet"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  egress {
    protocol       = "ANY"
    description    = "Any outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "web" {
  name        = "sg-web"
  description = "Web nodes"
  network_id  = yandex_vpc_network.main.id
  labels      = merge(var.labels, { role = "web" })

  ingress {
    protocol          = "TCP"
    description       = "HTTP from ALB"
    security_group_id = yandex_vpc_security_group.alb.id
    port              = 80
  }

  ingress {
    protocol          = "TCP"
    description       = "ALB health checks"
    predefined_target = "loadbalancer_healthchecks"
    port              = 80
  }

  ingress {
    protocol          = "TCP"
    description       = "SSH from bastion"
    security_group_id = yandex_vpc_security_group.bastion.id
    port              = 22
  }

  ingress {
    protocol          = "TCP"
    description       = "Node exporter from Prometheus"
    security_group_id = yandex_vpc_security_group.prometheus.id
    port              = 9100
  }

  ingress {
    protocol          = "TCP"
    description       = "Nginx log exporter from Prometheus"
    security_group_id = yandex_vpc_security_group.prometheus.id
    port              = 4040
  }

  egress {
    protocol       = "ANY"
    description    = "Any outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "prometheus" {
  name        = "sg-prometheus"
  description = "Prometheus node"
  network_id  = yandex_vpc_network.main.id
  labels      = merge(var.labels, { role = "prometheus" })

  ingress {
    protocol          = "TCP"
    description       = "SSH from bastion"
    security_group_id = yandex_vpc_security_group.bastion.id
    port              = 22
  }

  ingress {
    protocol       = "TCP"
    description    = "Prometheus UI from public subnets (Grafana and bastion)"
    v4_cidr_blocks = [var.cidr_blocks.public_a, var.cidr_blocks.public_b]
    port           = 9090
  }

  egress {
    protocol       = "ANY"
    description    = "Any outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "grafana" {
  name        = "sg-grafana"
  description = "Grafana node"
  network_id  = yandex_vpc_network.main.id
  labels      = merge(var.labels, { role = "grafana" })

  ingress {
    protocol       = "TCP"
    description    = "Grafana web access"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 3000
  }

  ingress {
    protocol          = "TCP"
    description       = "SSH from bastion"
    security_group_id = yandex_vpc_security_group.bastion.id
    port              = 22
  }

  ingress {
    protocol          = "TCP"
    description       = "Node exporter from Prometheus"
    security_group_id = yandex_vpc_security_group.prometheus.id
    port              = 9100
  }

  egress {
    protocol       = "ANY"
    description    = "Any outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "elasticsearch" {
  name        = "sg-elasticsearch"
  description = "Elasticsearch node"
  network_id  = yandex_vpc_network.main.id
  labels      = merge(var.labels, { role = "elasticsearch" })

  ingress {
    protocol          = "TCP"
    description       = "SSH from bastion"
    security_group_id = yandex_vpc_security_group.bastion.id
    port              = 22
  }

  ingress {
    protocol          = "TCP"
    description       = "HTTP from Kibana"
    security_group_id = yandex_vpc_security_group.kibana.id
    port              = 9200
  }

  ingress {
    protocol          = "TCP"
    description       = "HTTP from web nodes with Filebeat"
    security_group_id = yandex_vpc_security_group.web.id
    port              = 9200
  }

  ingress {
    protocol          = "TCP"
    description       = "HTTP from bastion for debugging"
    security_group_id = yandex_vpc_security_group.bastion.id
    port              = 9200
  }

  ingress {
    protocol          = "TCP"
    description       = "Node exporter from Prometheus"
    security_group_id = yandex_vpc_security_group.prometheus.id
    port              = 9100
  }

  egress {
    protocol       = "ANY"
    description    = "Any outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "kibana" {
  name        = "sg-kibana"
  description = "Kibana node"
  network_id  = yandex_vpc_network.main.id
  labels      = merge(var.labels, { role = "kibana" })

  ingress {
    protocol       = "TCP"
    description    = "Kibana web access"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  ingress {
    protocol          = "TCP"
    description       = "SSH from bastion"
    security_group_id = yandex_vpc_security_group.bastion.id
    port              = 22
  }

  ingress {
    protocol          = "TCP"
    description       = "Node exporter from Prometheus"
    security_group_id = yandex_vpc_security_group.prometheus.id
    port              = 9100
  }

  egress {
    protocol       = "ANY"
    description    = "Any outbound"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
