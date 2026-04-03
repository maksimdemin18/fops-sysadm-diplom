#  Курсовая работа на профессии "DevOps-инженер с нуля"

Содержание
==========
* [Задача](#Задача)
* [Инфраструктура](#Инфраструктура)
    * [Сайт](#Сайт)
    * [Мониторинг](#Мониторинг)
    * [Логи](#Логи)
    * [Сеть](#Сеть)
    * [Резервное копирование](#Резервное-копирование)
    * [Дополнительно](#Дополнительно)

---------

### Задача
Ключевая задача — разработать отказоустойчивую инфраструктуру для сайта, включающую мониторинг, сбор логов и резервное копирование основных данных. Инфраструктура должна размещаться в [Yandex Cloud](https://cloud.yandex.com/).

**Примечание**: в курсовой работе используется система мониторинга Prometheus. Вместо Prometheus вы можете использовать Zabbix. Задание для курсовой работы с использованием Zabbix находится по [ссылке](https://github.com/netology-code/fops-sysadm-diplom/blob/diplom-zabbix/README.md).

**Перед началом работы над дипломным заданием изучите [Инструкция по экономии облачных ресурсов](https://github.com/netology-code/devops-materials/blob/master/cloudwork.MD).**   

## Инфраструктура
Для развёртки инфраструктуры используйте Terraform и Ansible. 

Параметры виртуальной машины (ВМ) подбирайте по потребностям сервисов, которые будут на ней работать. 

Ознакомьтесь со всеми пунктами из этой секции, не беритесь сразу выполнять задание, не дочитав до конца. Пункты взаимосвязаны и могут влиять друг на друга.

### Сайт
Создайте две ВМ в разных зонах, установите на них сервер nginx, если его там нет. ОС и содержимое ВМ должно быть идентичным, это будут наши веб-сервера.

Используйте набор статичных файлов для сайта. Можно переиспользовать сайт из домашнего задания.

Создайте [Target Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/target-group), включите в неё две созданных ВМ.

Создайте [Backend Group](https://cloud.yandex.com/docs/application-load-balancer/concepts/backend-group), настройте backends на target group, ранее созданную. Настройте healthcheck на корень (/) и порт 80, протокол HTTP.

Создайте [HTTP router](https://cloud.yandex.com/docs/application-load-balancer/concepts/http-router). Путь укажите — /, backend group — созданную ранее.

Создайте [Application load balancer](https://cloud.yandex.com/en/docs/application-load-balancer/) для распределения трафика на веб-сервера, созданные ранее. Укажите HTTP router, созданный ранее, задайте listener тип auto, порт 80.

Протестируйте сайт
`curl -v <публичный IP балансера>:80` 

### Мониторинг
Создайте ВМ, разверните на ней Prometheus. На каждую ВМ из веб-серверов установите Node Exporter и [Nginx Log Exporter](https://github.com/martin-helmich/prometheus-nginxlog-exporter). Настройте Prometheus на сбор метрик с этих exporter.

Создайте ВМ, установите туда Grafana. Настройте её на взаимодействие с ранее развернутым Prometheus. Настройте дешборды с отображением метрик, минимальный набор — Utilization, Saturation, Errors для CPU, RAM, диски, сеть, http_response_count_total, http_response_size_bytes. Добавьте необходимые [tresholds](https://grafana.com/docs/grafana/latest/panels/thresholds/) на соответствующие графики.

### Логи
Cоздайте ВМ, разверните на ней Elasticsearch. Установите filebeat в ВМ к веб-серверам, настройте на отправку access.log, error.log nginx в Elasticsearch.

Создайте ВМ, разверните на ней Kibana, сконфигурируйте соединение с Elasticsearch.

### Сеть
Разверните один VPC. Сервера web, Prometheus, Elasticsearch поместите в приватные подсети. Сервера Grafana, Kibana, application load balancer определите в публичную подсеть.

Настройте [Security Groups](https://cloud.yandex.com/docs/vpc/concepts/security-groups) соответствующих сервисов на входящий трафик только к нужным портам.

Настройте ВМ с публичным адресом, в которой будет открыт только один порт — ssh. Настройте все security groups на разрешение входящего ssh из этой security group. Эта вм будет реализовывать концепцию bastion host. Потом можно будет подключаться по ssh ко всем хостам через этот хост.

### Резервное копирование
Создайте snapshot дисков всех ВМ. Ограничьте время жизни snaphot в неделю. Сами snaphot настройте на ежедневное копирование.

### Дополнительно
Не входит в минимальные требования. 

1. Для Prometheus можно реализовать альтернативный способ хранения данных — в базе данных PpostgreSQL. Используйте [Yandex Managed Service for PostgreSQL](https://cloud.yandex.com/en-ru/services/managed-postgresql). Разверните кластер из двух нод с автоматическим failover. Воспользуйтесь адаптером с https://github.com/CrunchyData/postgresql-prometheus-adapter для настройки отправки данных из Prometheus в новую БД.
2. Вместо конкретных ВМ, которые входят в target group, можно создать [Instance Group](https://cloud.yandex.com/en/docs/compute/concepts/instance-groups/), для которой настройте следующие правила автоматического горизонтального масштабирования: минимальное количество ВМ на зону — 1, максимальный размер группы — 3.
3. Можно добавить в Grafana оповещения с помощью Grafana alerts. Как вариант, можно также установить Alertmanager в ВМ к Prometheus, настроить оповещения через него.
4. В Elasticsearch добавьте мониторинг логов самого себя, Kibana, Prometheus, Grafana через filebeat. Можно использовать logstash тоже.
5. Воспользуйтесь Yandex Certificate Manager, выпустите сертификат для сайта, если есть доменное имя. Перенастройте работу балансера на HTTPS, при этом нацелен он будет на HTTP веб-серверов.

### Решение:


1. Архитектура решения

По заданию нужны:

2 web-ВМ в разных зонах;
ALB перед ними;
отдельные ВМ для Prometheus, Grafana, Elasticsearch, Kibana;
bastion host;
приватные и публичные подсети;
резервные копии всех ВМ.

Практически для такой схемы нужен ещё egress из приватных подсетей, иначе apt, Ansible и скачивание exporter на web/Prometheus/Elasticsearch в приватных сетях не будут работать. В Yandex Cloud для этого штатно используется NAT gateway с таблицей маршрутизации 0.0.0.0/0 на приватных подсетях; NAT gateway — региональный ресурс и даёт выход в интернет без назначения публичных IP самим приватным ВМ.

Размещение ресурсов

VPC: coursework-vpc

Подсети:

public-a — 10.10.10.0/24, ru-central1-a
public-b — 10.10.11.0/24, ru-central1-b
private-a — 10.10.20.0/24, ru-central1-a
private-b — 10.10.21.0/24, ru-central1-b

ВМ:

web-1 — private-a
web-2 — private-b
prometheus — private-a
elasticsearch — private-b
grafana — public-a
kibana — public-a
bastion — public-a

ALB:

ноды балансировщика размещаются в public-a и public-b
listener: HTTP, порт 80, публичный IPv4 — автоматически
route / → backend group → target group с web-1 и web-2

HTTP router в Yandex Cloud определяет правила маршрутизации HTTP-запросов к backend groups, а backend group содержит настройки распределения трафика и health checks. Для L7 load balancer в Terraform listener на HTTP можно привязать к http_router_id, а если external_ipv4_address не задан явно, публичный IPv4 назначается автоматически. Для корректной работы ALB нужны подcети в зонах размещения его узлов, и backend-серверы получают трафик именно от узлов балансировщика из этих подсетей.

2. Логика работы по разделам задания
Сайт
Две одинаковые web-ВМ в разных зонах.
На обеих Ansible ставит nginx и одинаковый набор статических файлов.
Terraform создаёт target group и включает туда две web-ВМ.
Terraform создаёт backend group с HTTP health check на /, порт 80.
Terraform создаёт HTTP router и virtual host с route /.
Terraform создаёт Application Load Balancer с listener на 80/tcp.
Проверка:
curl -v http://<ALB_PUBLIC_IP>:80
Мониторинг
На prometheus разворачивается Prometheus.
На web-1 и web-2 ставятся:
Node Exporter
Nginx Log Exporter
Prometheus собирает:
host-метрики с :9100
HTTP-метрики nginx access log с :4040
На grafana подключается Prometheus как data source.
Создаются dashboard-панели по USE-методике:
CPU
RAM
disk
network
http_response_count_total
http_response_size_bytes

Prometheus собирает метрики через scrape_configs, Node Exporter публикует системные метрики хоста, а prometheus-nginxlog-exporter читает access log и публикует метрики на /metrics; среди метрик экспортера есть <namespace>_http_response_count_total и <namespace>_http_response_size_bytes. Grafana имеет встроенную поддержку Prometheus как data source.

Логи
На отдельной ВМ разворачивается Elasticsearch.
На обеих web-ВМ ставится Filebeat.
Используется модуль nginx, который умеет разбирать access.log и error.log.
Filebeat отправляет события напрямую в Elasticsearch по HTTP API.
На отдельной ВМ разворачивается Kibana.
В kibana.yml настраивается соединение с Elasticsearch, а server.host меняется так, чтобы UI был доступен по сети.

Filebeat — это lightweight shipper для централизованной отправки логов; его nginx module разбирает access и error logs Nginx, а output.elasticsearch отправляет события напрямую в Elasticsearch HTTP API. Для удалённого доступа к Kibana требуется изменить server.host, так как по умолчанию она слушает localhost:5601.

Сеть
Один VPC.
Web, Prometheus, Elasticsearch — в приватных подсетях.
Grafana, Kibana, ALB, bastion — в публичных.
SSH к остальным ВМ — только через bastion.
На bastion открыт только 22/tcp.
Security groups минимальны по портам.

В Yandex Cloud security groups — основной механизм контроля доступа; если у security group нет правил, трафик блокируется по implicit deny. К объекту можно привязать до пяти security groups. Для ALB security group должны разрешать входящий пользовательский трафик на listener-порты, входящий трафик health checks на 30080 с источником Load balancer healthchecks, а backend-ВМ должны принимать трафик от ALB на порт backend-сервиса. Bastion host — это ВМ с публичным IP, работающая как jump host для доступа к приватным ВМ.

Резервное копирование

Для всех VM boot disk создаётся один yandex_compute_snapshot_schedule:

ежедневный запуск, например 0 2 * * *
retention = 168h = 1 неделя

Terraform-ресурс yandex_compute_snapshot_schedule поддерживает cron-выражение в schedule_policy.expression и retention через retention_period. При активной schedule новые снимки создаются автоматически, а старые удаляются по retention policy.

3. Предлагаемая структура репозитория
coursework/
├── terraform/
│   ├── providers.tf
│   ├── versions.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── network.tf
│   ├── security_groups.tf
│   ├── instances.tf
│   ├── alb.tf
│   ├── snapshots.tf
│   └── outputs.tf
└── ansible/
    ├── inventory.ini
    ├── ansible.cfg
    ├── site.yml
    ├── group_vars/
    │   └── all.yml
    ├── templates/
    │   ├── nginx-site.conf.j2
    │   ├── nginx-log-format.conf.j2
    │   ├── prometheus.yml.j2
    │   ├── prometheus-nginxlog-exporter.hcl.j2
    │   ├── filebeat.yml.j2
    │   ├── kibana.yml.j2
    │   └── elasticsearch.yml.j2
    ├── files/
    │   └── site/
    │       ├── index.html
    │       ├── css/
    │       └── img/
    └── roles/
        ├── common/
        ├── web/
        ├── prometheus/
        ├── grafana/
        ├── elasticsearch/
        ├── kibana/
        ├── filebeat/
        └── exporters/
4. Terraform: каркас инфраструктуры
4.1. Провайдер
terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.138.0"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
  token     = var.yc_token
}
4.2. Сеть, подсети, NAT gateway
resource "yandex_vpc_network" "this" {
  name = "coursework-vpc"
}

resource "yandex_vpc_gateway" "nat" {
  name = "coursework-nat"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private_rt" {
  name       = "coursework-private-rt"
  network_id = yandex_vpc_network.this.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat.id
  }
}

resource "yandex_vpc_subnet" "public_a" {
  name           = "public-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = ["10.10.10.0/24"]
}

resource "yandex_vpc_subnet" "public_b" {
  name           = "public-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = ["10.10.11.0/24"]
}

resource "yandex_vpc_subnet" "private_a" {
  name           = "private-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = ["10.10.20.0/24"]
  route_table_id = yandex_vpc_route_table.private_rt.id
}

resource "yandex_vpc_subnet" "private_b" {
  name           = "private-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.this.id
  v4_cidr_blocks = ["10.10.21.0/24"]
  route_table_id = yandex_vpc_route_table.private_rt.id
}

Такой способ соответствует официальной схеме Yandex Cloud: NAT gateway + route table + привязка route table к приватным подсетям.

4.3. Security Groups

Ниже логика правил. В Terraform это удобно оформить через yandex_vpc_security_group, используя ingress/egress, security_group_id для ссылок между SG и predefined_target = "loadbalancer_healthchecks" для health checks. Провайдер поддерживает именно такие поля.

bastion-sg
ingress 22/tcp от 0.0.0.0/0
egress ANY везде
alb-sg
ingress 80/tcp от 0.0.0.0/0
ingress 30080/tcp от loadbalancer_healthchecks
egress 80/tcp в private CIDR 10.10.20.0/24, 10.10.21.0/24
web-sg
ingress 80/tcp от alb-sg
ingress 22/tcp от bastion-sg
ingress 9100/tcp от prometheus-sg
ingress 4040/tcp от prometheus-sg
egress ANY везде
prometheus-sg
ingress 22/tcp от bastion-sg
ingress 9090/tcp от grafana-sg
egress 9100/tcp, 4040/tcp в web-sg
grafana-sg
ingress 3000/tcp от 0.0.0.0/0
ingress 22/tcp от bastion-sg
egress 9090/tcp на prometheus
elasticsearch-sg
ingress 22/tcp от bastion-sg
ingress 9200/tcp от kibana-sg
ingress 9200/tcp от web-sg
egress ANY везде
kibana-sg
ingress 5601/tcp от 0.0.0.0/0
ingress 22/tcp от bastion-sg
egress 9200/tcp на Elasticsearch

Такой набор соблюдает требование “только нужные порты” и при этом не ломает связность сервисов. Для ALB правила на 80/tcp и 30080/tcp обязательны с точки зрения официальной документации по security groups для load balancer.

4.4. Виртуальные машины

Ниже — идея объявления ВМ. Полный HCL можно сделать через for_each по карте local.vms.

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

locals {
  vms = {
    bastion = {
      zone      = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public_a.id
      nat       = true
      sg_ids    = [yandex_vpc_security_group.bastion.id]
      cores     = 2
      memory    = 2
    }
    web-1 = {
      zone      = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.private_a.id
      nat       = false
      sg_ids    = [yandex_vpc_security_group.web.id]
      cores     = 2
      memory    = 2
    }
    web-2 = {
      zone      = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.private_b.id
      nat       = false
      sg_ids    = [yandex_vpc_security_group.web.id]
      cores     = 2
      memory    = 2
    }
    prometheus = {
      zone      = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.private_a.id
      nat       = false
      sg_ids    = [yandex_vpc_security_group.prometheus.id]
      cores     = 2
      memory    = 4
    }
    grafana = {
      zone      = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public_a.id
      nat       = true
      sg_ids    = [yandex_vpc_security_group.grafana.id]
      cores     = 2
      memory    = 2
    }
    elasticsearch = {
      zone      = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.private_b.id
      nat       = false
      sg_ids    = [yandex_vpc_security_group.elasticsearch.id]
      cores     = 4
      memory    = 8
    }
    kibana = {
      zone      = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.public_a.id
      nat       = true
      sg_ids    = [yandex_vpc_security_group.kibana.id]
      cores     = 2
      memory    = 4
    }
  }
}

resource "yandex_compute_instance" "vm" {
  for_each = local.vms

  name        = each.key
  zone        = each.value.zone
  platform_id = "standard-v3"

  resources {
    cores  = each.value.cores
    memory = each.value.memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 15
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = each.value.subnet_id
    nat                = each.value.nat
    security_group_ids = each.value.sg_ids
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
}
5. Terraform: Application Load Balancer

В Yandex Cloud ALB строится цепочкой:
target group → backend group → HTTP router → virtual host → load balancer listener. Health checks на backend группы можно включать на port 80, path /. Listener с пустым external_ipv4_address {} получает публичный IP автоматически.

resource "yandex_alb_target_group" "web" {
  name = "web-target-group"

  target {
    subnet_id  = yandex_vpc_subnet.private_a.id
    ip_address = yandex_compute_instance.vm["web-1"].network_interface[0].ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.private_b.id
    ip_address = yandex_compute_instance.vm["web-2"].network_interface[0].ip_address
  }
}

resource "yandex_alb_backend_group" "web" {
  name = "web-backend-group"

  http_backend {
    name             = "web-backend"
    port             = 80
    weight           = 1
    target_group_ids = [yandex_alb_target_group.web.id]

    load_balancing_config {
      panic_threshold = 50
    }

    healthcheck {
      timeout             = "3s"
      interval            = "5s"
      healthy_threshold   = 2
      unhealthy_threshold = 2

      http_healthcheck {
        path = "/"
      }
    }
  }
}

resource "yandex_alb_http_router" "web" {
  name = "web-http-router"
}

resource "yandex_alb_virtual_host" "web" {
  name           = "web-vhost"
  http_router_id = yandex_alb_http_router.web.id
  authority      = ["*"]

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
        timeout          = "60s"
      }
    }
  }
}

resource "yandex_alb_load_balancer" "web" {
  name               = "web-alb"
  network_id         = yandex_vpc_network.this.id
  security_group_ids = [yandex_vpc_security_group.alb.id]

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

  listener {
    name = "http-80"
    endpoint {
      address {
        external_ipv4_address {}
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web.id
      }
    }
  }
}

Проверка после terraform apply:

curl -v http://<ALB_PUBLIC_IP>:80
6. Terraform: snapshot schedule
locals {
  snapshot_disk_ids = [
    for vm in values(yandex_compute_instance.vm) : vm.boot_disk[0].disk_id
  ]
}

resource "yandex_compute_snapshot_schedule" "daily" {
  name = "daily-snapshots-1-week"

  schedule_policy {
    expression = "0 2 * * *"
  }

  retention_period = "168h"

  snapshot_spec {
    description = "daily snapshots for coursework"
  }

  disk_ids = local.snapshot_disk_ids
}

Это закрывает требование: ежедневный snapshot + срок жизни 1 неделя.

7. Ansible: inventory и доступ через bastion

ansible/inventory.ini:

[all:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_ed25519
ansible_ssh_common_args='-o ProxyJump=ubuntu@<BASTION_PUBLIC_IP>'

[web]
web-1 ansible_host=10.10.20.10
web-2 ansible_host=10.10.21.10

[prometheus]
prometheus ansible_host=10.10.20.20

[grafana]
grafana ansible_host=<GRAFANA_PUBLIC_IP>

[elasticsearch]
elasticsearch ansible_host=10.10.21.20

[kibana]
kibana ansible_host=<KIBANA_PUBLIC_IP>

[bastion]
bastion ansible_host=<BASTION_PUBLIC_IP>

Так bastion выполняет именно ту роль, которую требует задание: прямой SSH извне есть только на jump host, остальной SSH идёт через него. Концепция bastion host в Yandex Cloud описана именно так.

8. Ansible: общий playbook

ansible/site.yml:

- hosts: all
  become: true
  roles:
    - common

- hosts: web
  become: true
  roles:
    - web
    - exporters
    - filebeat

- hosts: prometheus
  become: true
  roles:
    - prometheus

- hosts: grafana
  become: true
  roles:
    - grafana

- hosts: elasticsearch
  become: true
  roles:
    - elasticsearch

- hosts: kibana
  become: true
  roles:
    - kibana
9. Ключевые роли Ansible
9.1. role web

Задачи:

установить nginx
развернуть одинаковый статический сайт
настроить access/error logs
добавить нужный log_format
nginx site config

templates/nginx-site.conf.j2

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/site;
    index index.html;

    access_log /var/log/nginx/access.log main_ext;
    error_log  /var/log/nginx/error.log warn;

    location / {
        try_files $uri $uri/ =404;
    }
}
log format для nginx log exporter

templates/nginx-log-format.conf.j2

log_format main_ext '$remote_addr - $remote_user [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    '"$http_referer" "$http_user_agent" "$http_x_forwarded_for" '
                    '$request_length $request_time $upstream_response_time';

Это важно: exporter умеет отдавать не только count/size, но и request/upstream time, если соответствующие поля присутствуют в access log format. Required-метрики http_response_count_total и http_response_size_bytes он публикует в любом случае, а latency/request size появляются при наличии переменных $request_time, $upstream_response_time, $request_length в логе.

9.2. role exporters
Node Exporter

На Ubuntu можно установить пакет или поставить бинарник и systemd unit. Node Exporter — стандартный способ собрать CPU/RAM/disk/network метрики хоста.

Nginx Log Exporter

У экспортера есть DEB-пакеты и systemd unit; конфиг обычно кладётся в /etc/prometheus-nginxlog-exporter.hcl, а сам exporter слушает метрики на :4040.

templates/prometheus-nginxlog-exporter.hcl.j2

listen {
  port = 4040
  address = "0.0.0.0"
}

namespace "nginx" {
  source_files = ["/var/log/nginx/access.log"]
  format = '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" "$http_x_forwarded_for" $request_length $request_time $upstream_response_time'
}
9.3. role prometheus

templates/prometheus.yml.j2

global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: ['localhost:9090']

  - job_name: node_exporter
    static_configs:
      - targets:
          - '10.10.20.10:9100'
          - '10.10.21.10:9100'

  - job_name: nginx_log_exporter
    static_configs:
      - targets:
          - '10.10.20.10:4040'
          - '10.10.21.10:4040'

Prometheus собирает данные по scrape_configs, где каждый job определяет набор targets. Это соответствует стандартной модели Prometheus.

9.4. role grafana

Задачи:

установить Grafana
открыть UI на 3000
добавить data source Prometheus
импортировать/создать dashboards

Подключение Prometheus в Grafana делается как отдельный Prometheus data source.

9.5. role elasticsearch

Задачи:

установить Elasticsearch из официального Debian-репозитория/пакета
настроить network.host
запустить как systemd service

Elastic официально поддерживает Debian package для Elasticsearch, а конфигурация делается через elasticsearch.yml, включая network.host.

templates/elasticsearch.yml.j2

cluster.name: coursework-es
node.name: elasticsearch-1
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
9.6. role filebeat

Задачи:

установить Filebeat
включить nginx module
указать access.log и error.log
настроить отправку в Elasticsearch

templates/filebeat.yml.j2

filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: false

setup.template.enabled: true

output.elasticsearch:
  hosts: ["http://10.10.21.20:9200"]

modules.d/nginx.yml

- module: nginx
  access:
    enabled: true
    var.paths: ["/var/log/nginx/access.log"]
  error:
    enabled: true
    var.paths: ["/var/log/nginx/error.log"]

Это соответствует документации: nginx module разбирает access и error, а Filebeat умеет отправлять события напрямую в Elasticsearch output.

9.7. role kibana

templates/kibana.yml.j2

server.host: "0.0.0.0"
server.port: 5601
elasticsearch.hosts: ["http://10.10.21.20:9200"]

Для доступа к Kibana снаружи нужно изменить server.host, а саму Kibana направить на Elasticsearch через elasticsearch.hosts.

10. Дашборды Grafana: что именно показать

Ниже — минимальный набор панелей, который закрывает задание.

CPU

Utilization

100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

Thresholds

warning: 70
critical: 90
RAM

Utilization

100 * (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes))

Thresholds

warning: 80
critical: 90
Disk

Utilization

100 * (1 - (node_filesystem_avail_bytes{fstype!~"tmpfs|overlay"} / node_filesystem_size_bytes{fstype!~"tmpfs|overlay"}))

Thresholds

warning: 75
critical: 85
Network

Saturation RX

sum by (instance) (rate(node_network_receive_bytes_total{device!~"lo"}[5m]))

Saturation TX

sum by (instance) (rate(node_network_transmit_bytes_total{device!~"lo"}[5m]))

Errors

sum by (instance) (
  rate(node_network_receive_errs_total{device!~"lo"}[5m]) +
  rate(node_network_transmit_errs_total{device!~"lo"}[5m])
)
HTTP response count
sum by (instance, status) (rate(nginx_http_response_count_total[5m]))
HTTP response size
sum by (instance) (rate(nginx_http_response_size_bytes[5m]))

Если вы хотите панель latency, можно добавить:

rate(nginx_http_response_time_seconds_sum[5m])
/
rate(nginx_http_response_time_seconds_count[5m])
11. Порядок выполнения работы
Подготовить service account и токен для Terraform.
Выполнить:
cd terraform
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
Получить публичные IP bastion, grafana, kibana, ALB.
Сформировать ansible/inventory.ini.
Выполнить:
cd ansible
ansible-playbook -i inventory.ini site.yml
Проверить сайт:
curl -v http://<ALB_PUBLIC_IP>:80
Проверить отказоустойчивость:
остановить nginx на web-1
снова выполнить curl
убедиться, что сайт доступен через web-2
Проверить Prometheus Targets (/targets).
Проверить dashboards в Grafana.
Проверить индекс и документы в Elasticsearch.
Проверить отображение логов в Kibana Discover.
Проверить наличие snapshot schedule и создаваемых snapshot.
12. Что написать в пояснительной записке
Цель работы

Разработать отказоустойчивую инфраструктуру для статического сайта в Yandex Cloud с использованием Terraform и Ansible, включающую балансировку нагрузки, мониторинг, централизованный сбор логов, сегментацию сети и резервное копирование.

Принятые технические решения

Для развёртывания инфраструктуры выбран подход Infrastructure as Code: Terraform используется для создания облачных ресурсов, Ansible — для конфигурации операционных систем и приложений. Для обеспечения отказоустойчивости сайт размещён на двух идентичных web-серверах в разных зонах доступности, а пользовательский трафик распределяется через Yandex Application Load Balancer. Для изоляции сервисов создан один VPC с публичными и приватными подсетями. Для выхода приватных ВМ в интернет используется NAT gateway, что позволяет не назначать этим узлам публичные IP-адреса. Для администрирования используется bastion host. Решение по ALB, NAT gateway, bastion host, security groups и snapshot schedule соответствует штатным механизмам Yandex Cloud.

Мониторинг

В качестве системы мониторинга используется Prometheus. На web-серверах установлены Node Exporter для системных метрик и Nginx Log Exporter для метрик HTTP-ответов по access log. Визуализация реализована в Grafana, где настроены панели Utilization, Saturation и Errors для CPU, памяти, дисков и сети, а также графики http_response_count_total и http_response_size_bytes. Такой подход соответствует стандартной модели Prometheus со scrape_configs, а Grafana подключается к Prometheus как к data source.

Логи

Для централизованного сбора логов используется стек Elasticsearch + Kibana. На web-серверах установлен Filebeat с активированным модулем nginx, который собирает и разбирает access.log и error.log, после чего отправляет события напрямую в Elasticsearch. Анализ логов выполняется в Kibana.

Резервное копирование

Для всех виртуальных машин настроено резервное копирование через snapshot schedule: снимки дисков создаются ежедневно, а срок хранения ограничен одной неделей. Это реализовано штатным Terraform-ресурсом yandex_compute_snapshot_schedule с cron-выражением и параметром retention_period.

13. Что показать на защите

Покажите последовательно:

terraform plan / terraform apply
список ВМ и подсетей в Yandex Cloud
target group, backend group, HTTP router и ALB
curl -v http://<ALB_PUBLIC_IP>:80
остановку одного web-сервера и повторный curl
страницу /targets в Prometheus
Grafana dashboard
индексы в Elasticsearch
логи nginx в Kibana Discover
snapshot schedule и список snapshot
14. Дополнительно
PostgreSQL как long-term storage для Prometheus

Если делать дополнительную часть, то логика такая:

поднять Managed Service for PostgreSQL минимум из двух хостов;
использовать CrunchyData/postgresql-prometheus-adapter как remote storage adapter;
включить remote_write на стороне Prometheus.

У Yandex Managed PostgreSQL кластер из двух и более хостов является высокодоступным, а при отказе мастера выполняется автоматический failover. Сам adapter CrunchyData предназначен именно для использования PostgreSQL как long-term storage для временных рядов Prometheus.

HTTPS

Если есть домен, можно добавить Yandex Certificate Manager и перевести ALB на TLS listener. Certificate Manager используется в том числе с Application Load Balancer для TLS termination.

15. Итоговый вывод

В работе спроектирована отказоустойчивая инфраструктура сайта в Yandex Cloud. Доступность сайта обеспечивается двумя одинаковыми web-серверами в разных зонах доступности и L7-балансировщиком Yandex Application Load Balancer. Сетевое разделение выполнено с помощью одного VPC, публичных и приватных подсетей, security groups и bastion host. 
Мониторинг реализован через Prometheus и Grafana, централизованный сбор логов — через Filebeat, Elasticsearch и Kibana, а резервное копирование — через ежедневные snapshots с недельным сроком хранения. Архитектура соответствует требованиям задания и может быть полностью воспроизведена средствами Terraform и Ansible.
