output "alb_public_ip" {
  description = "Публичный IP ALB"
  value       = try(yandex_alb_load_balancer.main.listener[0].endpoint[0].address[0].external_ipv4_address[0].address, null)
}

output "bastion_public_ip" {
  description = "Публичный IP bastion"
  value       = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

output "grafana_public_ip" {
  description = "Публичный IP Grafana"
  value       = yandex_compute_instance.grafana.network_interface.0.nat_ip_address
}

output "kibana_public_ip" {
  description = "Публичный IP Kibana"
  value       = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}

output "ansible_inventory_path" {
  description = "Путь к сгенерированному inventory"
  value       = local_file.ansible_inventory.filename
}
