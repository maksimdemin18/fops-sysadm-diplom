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

