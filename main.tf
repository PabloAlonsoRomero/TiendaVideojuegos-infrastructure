terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~>2.0"
    }
  }

  backend "s3" {
    endpoints = {
      s3 = "https://sfo3.digitaloceanspaces.com"
    }
    bucket                      = "tienda-videojuegos"
    key                         = "terraform.tfstate"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
    region                      = "us-east-1"
  }

}

provider "digitalocean" {
  token = var.TIENDA_TOKEN
}

resource "digitalocean_project" "tienda_server_project" {
  name        = "tienda_server_project"
  description = "Un servidor para la tienda de videojuegos"
  resources   = [digitalocean_droplet.tienda_server_droplet.urn]
}

resource "digitalocean_ssh_key" "tienda_server_ssh_key" {
  name       = "tienda_server_key"
  public_key = file("./keys/tienda_server.pub")
}

resource "digitalocean_droplet" "tienda_server_droplet" {
  name      = "tienda-server"
  size      = "s-2vcpu-4gb-120gb-intel"
  image     = "ubuntu-24-04-x64"
  region    = "sfo3"
  ssh_keys  = [digitalocean_ssh_key.tienda_server_ssh_key.id]
  user_data = file("./docker-install.sh")

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /projects",
      "mkdir -p /volumes/nginx/html",
      "mkdir -p /volumes/nginx/certs",
      "mkdir -p /volumes/nginx/vhostd",
      "touch /projects/.env",
      "echo \"DB_USER=${var.DB_USER}\" >> /projects/.env",
      "echo \"DB_PASSWORD=${var.DB_PASSWORD}\" >> /projects/.env",
      "echo \"DB_NAME=${var.DB_NAME}\" >> /projects/.env",
      "echo \"DB_CLUSTER=${var.DB_CLUSTER}\" >> /projects/.env",
      "echo \"DOMAIN=${var.DOMAIN}\" >> /projects/.env",
      "echo \"USER_EMAIL=${var.USER_EMAIL}\" >> /projects/.env"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(("./keys/tienda_server"))
      host        = self.ipv4_address
    }
  }

  provisioner "file" {
    source      = "./containers/docker-compose.yml"
    destination = "/projects/docker-compose.yml"
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file(("./keys/tienda_server"))
      host        = self.ipv4_address
    }
  }
}

resource "time_sleep" "wait_docker_install" {
  depends_on      = [digitalocean_droplet.tienda_server_droplet]
  create_duration = "130s"
}

resource "time_sleep" "wait_node_install" {
  depends_on      = [digitalocean_droplet.tienda_server_droplet]
  create_duration = "130s"
}

resource "null_resource" "init_api" {
  depends_on = [time_sleep.wait_node_install]
  provisioner "remote-exec" {
    inline = [
      "cd /projects",
      "docker-compose up -d"
    ]
    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("./keys/tienda_server")
      host        = digitalocean_droplet.tienda_server_droplet.ipv4_address
    }
  }
}

output "ip" {
  value = digitalocean_droplet.tienda_server_droplet.ipv4_address
}

# ssh -i ./keys/tienda_server root@$(terraform output ip)