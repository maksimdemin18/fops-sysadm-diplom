variable "cloud_id" {
  description = "ID облака Yandex Cloud"
  type        = string
}

variable "folder_id" {
  description = "ID каталога Yandex Cloud"
  type        = string
}

variable "zone" {
  description = "Зона по умолчанию для провайдера"
  type        = string
  default     = "ru-central1-a"
}

variable "vm_user" {
  description = "Пользователь в гостевой ОС"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Путь до публичного SSH-ключа"
  type        = string
}

variable "private_key_path" {
  description = "Путь до приватного SSH-ключа для Ansible inventory"
  type        = string
}

variable "image_family" {
  description = "Семейство образов ОС"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "network_name" {
  description = "Имя VPC"
  type        = string
  default     = "coursework-vpc"
}

variable "web_resources" {
  description = "Ресурсы web-серверов"
  type = object({
    cores  = number
    memory = number
    disk   = number
  })
  default = {
    cores  = 2
    memory = 2
    disk   = 15
  }
}

variable "service_resources" {
  description = "Ресурсы service-узлов"
  type = object({
    prometheus_cores  = number
    prometheus_memory = number
    prometheus_disk   = number
    grafana_cores     = number
    grafana_memory    = number
    grafana_disk      = number
    elastic_cores     = number
    elastic_memory    = number
    elastic_disk      = number
    kibana_cores      = number
    kibana_memory     = number
    kibana_disk       = number
    bastion_cores     = number
    bastion_memory    = number
    bastion_disk      = number
  })
  default = {
    prometheus_cores  = 2
    prometheus_memory = 4
    prometheus_disk   = 20
    grafana_cores     = 2
    grafana_memory    = 2
    grafana_disk      = 15
    elastic_cores     = 2
    elastic_memory    = 4
    elastic_disk      = 30
    kibana_cores      = 2
    kibana_memory     = 2
    kibana_disk       = 15
    bastion_cores     = 2
    bastion_memory    = 2
    bastion_disk      = 10
  }
}

variable "cidr_blocks" {
  description = "CIDR-сети проекта"
  type = object({
    public_a  = string
    public_b  = string
    private_a = string
    private_b = string
  })
  default = {
    public_a  = "10.10.10.0/24"
    public_b  = "10.10.20.0/24"
    private_a = "10.10.110.0/24"
    private_b = "10.10.120.0/24"
  }
}

variable "labels" {
  description = "Общие labels"
  type        = map(string)
  default = {
    project = "devops-coursework"
    owner   = "student"
  }
}
