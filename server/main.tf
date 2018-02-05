# main.tf
variable "do_token" {                     # Your DigitalOcean API Token
  type        = "string"
}
variable "do_domain" {                    # The domain you have hooked up to Digital Ocean's Networking panel
  type        = "string"
}
variable "local_ssh_key_path" {           # The path on your local machine to the SSH private key (defaults to "~/.ssh/id_rsa")
  type        = "string"
  default     = "~/.ssh/id_rsa"
}
variable "local_ssh_key_path_public" {    # The path on your local machine to the SSH public key (defaults to "~/.ssh/id_rsa.pub")
  type        = "string"
  default     = "~/.ssh/id_rsa.pub"
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = "${var.do_token}"
}

# Create a new DO SSH key
resource "digitalocean_ssh_key" "terraform_local" {
  name       = "Docker Swarm"
  public_key = "${file("${var.local_ssh_key_path_public}")}"
}

resource "digitalocean_droplet" "docker_swarm_manager" {
  name        = "swarm.${var.do_domain}"
  region = "nyc3"
  size = "1GB"
  image = "ubuntu-16-04-x64"
  ssh_keys    = ["${digitalocean_ssh_key.terraform_local.id}"]
  private_networking = true

  provisioner "remote-exec" {
    script = "install-docker.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "docker swarm init --advertise-addr ${digitalocean_droplet.docker_swarm_manager.ipv4_address_private}"
    ]
  }

}

data "external" "swarm_join_token" {
  program = ["./get-join-tokens.sh"]
  query = {
    host = "${digitalocean_droplet.docker_swarm_manager.ipv4_address}"
  }
}

resource "digitalocean_droplet" "docker_swarm_worker" {
  count = 3
  name = "docker-swarm-worker-${count.index}"
  region = "nyc3"
  size = "1GB"
  image = "ubuntu-16-04-x64"
  ssh_keys = ["${digitalocean_ssh_key.terraform_local.id}"]
  private_networking = true

  provisioner "remote-exec" {
    script = "install-docker.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "docker swarm join --token ${data.external.swarm_join_token.result.worker} ${digitalocean_droplet.docker_swarm_manager.ipv4_address_private}:2377"
    ]
  }
}
