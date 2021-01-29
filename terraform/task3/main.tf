provider "google" {
  credentials = file("../terraform-sa.json")

  project = var.project_id
  region  = var.region_default
  zone    = var.zone_default
}

resource "google_compute_network" "vpc" {
  name                    = var.task_title
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "sub-dmz-0" {
  name          = "sub-dmz-0-${var.task_title}"
  ip_cidr_range = "10.10.10.0/24"
  region        = var.region_default
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "sub-priv-0" {
  name          = "sub-priv-0-${var.task_title}"
  ip_cidr_range = "10.10.11.0/24"
  region        = var.region_default
  network       = google_compute_network.vpc.id
}


resource "google_compute_firewall" "deny-all" {
  name    = "deny-all-${var.task_title}"
  network = google_compute_network.vpc.name

  direction = "EGRESS"
  priority  = "1001"
  deny {
    protocol = "all"
  }

}

resource "google_compute_firewall" "allow-to-internet" {
  name    = "allow-to-internet-${var.task_title}"
  network = google_compute_network.vpc.name

  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }

  target_tags = [
    "sub-dmz-0-${var.task_title}",
    "sub-priv-0-${var.task_title}"
  ]
}

resource "google_compute_firewall" "allow-internal" {
  name    = "allow-internal-${var.task_title}"
  network = google_compute_network.vpc.name

  direction          = "EGRESS"
  destination_ranges = ["10.10.0.0/16"]

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh-to-jumphost-${var.task_title}"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["${var.pub_ip}/32"]
  target_tags   = ["jumphost-${var.task_title}"]
}

resource "google_compute_firewall" "allow-ssh-from-jumphost" {
  name    = "allow-ssh-from-jumphost-${var.task_title}"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags = ["jumphost-${var.task_title}"]
}

resource "google_compute_router" "vpc-router" {
  name    = "${var.task_title}-router"
  network = google_compute_network.vpc.name
  region  = var.region_default
}

resource "google_compute_router_nat" "vpc-nat" {
  name   = "${var.task_title}-nat"
  router = google_compute_router.vpc-router.name
  region = google_compute_router.vpc-router.region

  nat_ip_allocate_option = "AUTO_ONLY"

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.sub-dmz-0.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  subnetwork {
    name                    = google_compute_subnetwork.sub-priv-0.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_instance" "jumphost" {
  name         = "jumphost-${var.task_title}"
  hostname     = "jumphost.${var.task_title}"
  machine_type = "f1-micro"
  zone         = var.zone_default

  tags = ["jumphost-${var.task_title}", "sub-dmz-0-${var.task_title}"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.sub-dmz-0.name
    access_config {
    }
  }
}

resource "google_compute_instance" "dev-0" {
  name         = "dev-0-${var.task_title}"
  hostname     = "dev-0.${var.task_title}"
  machine_type = "f1-micro"
  zone         = var.zone_default

  tags = ["sub-priv-0-${var.task_title}"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.sub-priv-0.name
  }

  service_account {
    email  = "compute@dev-project-302319.iam.gserviceaccount.com"
    scopes = ["storage-full"]
  }
}