resource "google_compute_instance" "default" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = var.network
    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    ssh-keys = var.ssh_keys
  }

  service_account {
    email  = var.service_account_email
    scopes = var.scopes
  }
}

output "instance_id" {
  value = google_compute_instance.default.id
}

output "instance_ip" {
  value = google_compute_instance.default.network_interface[0].access_config[0].nat_ip
}