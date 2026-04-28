resource "yandex_compute_snapshot_schedule" "daily" {
  name             = "coursework-daily-snapshots"
  description      = "Daily snapshots for all coursework VMs"
  retention_period = "168h"
  labels           = merge(var.labels, { role = "backup" })

  schedule_policy {
    expression = "0 2 * * *"
  }

  snapshot_spec {
    description = "Daily coursework snapshot"
    labels = {
      managed_by = "terraform"
      purpose    = "coursework-backup"
    }
  }

  disk_ids = [
    yandex_compute_instance.bastion.boot_disk.0.disk_id,
    yandex_compute_instance.web1.boot_disk.0.disk_id,
    yandex_compute_instance.web2.boot_disk.0.disk_id,
    yandex_compute_instance.prometheus.boot_disk.0.disk_id,
    yandex_compute_instance.elasticsearch.boot_disk.0.disk_id,
    yandex_compute_instance.grafana.boot_disk.0.disk_id,
    yandex_compute_instance.kibana.boot_disk.0.disk_id,
  ]
}
