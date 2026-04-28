resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory/prod.ini"
  content = templatefile("${path.module}/../ansible/inventory/prod.ini.tpl", {
    vm_user               = var.vm_user
    private_key_path      = var.private_key_path
    bastion_public_ip     = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
    web1_private_ip       = yandex_compute_instance.web1.network_interface.0.ip_address
    web2_private_ip       = yandex_compute_instance.web2.network_interface.0.ip_address
    prometheus_private_ip = yandex_compute_instance.prometheus.network_interface.0.ip_address
    elastic_private_ip    = yandex_compute_instance.elasticsearch.network_interface.0.ip_address
    grafana_private_ip    = yandex_compute_instance.grafana.network_interface.0.ip_address
    grafana_public_ip     = yandex_compute_instance.grafana.network_interface.0.nat_ip_address
    kibana_private_ip     = yandex_compute_instance.kibana.network_interface.0.ip_address
    kibana_public_ip      = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
  })
}
