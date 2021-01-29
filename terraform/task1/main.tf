provider "google" {
  credentials = file("../terraform-sa.json")

  project = var.project_id
  region  = var.region_default
  zone    = var.zone_default
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "sub-dmz-0" {
  name          = "sub-dmz-0"
  ip_cidr_range = "10.0.10.0/24"
  region        = var.region_default
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "sub-priv-0" {
  name          = "sub-priv-0"
  ip_cidr_range = "10.0.11.0/24"
  region        = var.region_default
  network       = google_compute_network.vpc.id
}

resource "google_compute_subnetwork" "sub-priv-1" {
  name          = "sub-priv-1"
  ip_cidr_range = "10.0.12.0/24"
  region        = var.region_default
  network       = google_compute_network.vpc.id
}

resource "google_compute_firewall" "deny-all" {
  name    = "deny-all"
  network = google_compute_network.vpc.name

  direction = "EGRESS"
  priority  = "1001"
  deny {
    protocol = "all"
  }

}

resource "google_compute_firewall" "allow-to-internet" {
  name    = "allow-to-internet"
  network = google_compute_network.vpc.name

  direction          = "EGRESS"
  destination_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "all"
  }

  target_tags = [
    "sub-dmz-0",
    "sub-priv-0"
  ]
}

resource "google_compute_firewall" "allow-internal" {
  name    = "allow-internal"
  network = google_compute_network.vpc.name

  direction          = "EGRESS"
  destination_ranges = ["10.0.0.0/16"]

  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh-to-jumphost"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["${var.pub_ip}/32"]
  target_tags   = ["jumphost"]
}

resource "google_compute_firewall" "allow-ssh-from-jumphost" {
  name    = "allow-ssh-from-jumphost"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags = ["jumphost"]
}

resource "google_compute_router" "vpc-router" {
  name    = "${var.vpc_name}-router"
  network = google_compute_network.vpc.name
  region  = var.region_default
}

resource "google_compute_router_nat" "vpc-nat" {
  name   = "${var.vpc_name}-nat"
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
  name         = "jumphost"
  hostname     = "jumphost.test"
  machine_type = "f1-micro"
  zone         = var.zone_default

  tags = ["jumphost", "sub-dmz-0"]

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
  name         = "dev-0"
  hostname     = "dev-0.test"
  machine_type = "f1-micro"
  zone         = var.zone_default

  tags = ["sub-priv-0"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.sub-priv-0.name
  }
}

resource "google_compute_instance" "dev-1" {
  name         = "dev-1"
  hostname     = "dev-1.test"
  machine_type = "f1-micro"
  zone         = var.zone_default

  tags = ["sub-dev-1"]

  boot_disk {
    initialize_params {
      image = "centos-cloud/centos-7"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.sub-priv-1.name
  }
}

