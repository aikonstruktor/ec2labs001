provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# --- Network Layer ---
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = var.vpc_name }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.vpc_name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1)
  map_public_ip_on_launch = true
  tags                    = { Name = "${var.vpc_name}-public" }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.rt.id
}

# --- Security Group (Allowing Port 22) ---
resource "aws_security_group" "ssh_access" {
  name        = "allow-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # Uses variable for security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- SSH Key Pair ---
# This assumes you have a key at ~/.ssh/id_rsa.pub
resource "aws_key_pair" "deployer" {
  key_name   = "${var.ec2_name}-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# --- EC2 Instance ---
resource "aws_instance" "devbox" {
  ami                    = "${var.ec2_ami_id}" 
  instance_type          = "t3.xlarge"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ssh_access.id]
  key_name               = aws_key_pair.deployer.key_name

  tags = { Name = var.ec2_name }

  # SSH connection settings
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  # 1. Copy id_ed25519 from your laptop to EC2 ~/.ssh
  provisioner "file" {
    source      = "~/.ssh/id_ed25519_toec2"
    destination = "/home/ubuntu/.ssh/id_ed25519"
  }

   # 2. Set permissions + install packages
  provisioner "remote-exec" {
    inline = [
      # Fix SSH permissions
      "chmod 700 /home/ubuntu/.ssh",
      "chmod 600 /home/ubuntu/.ssh/id_ed25519",
      "chown -R ubuntu:ubuntu /home/ubuntu/.ssh",

      # Install packages
      "sudo apt update -y",
      "sudo apt install -y python3.12-venv postgresql-client nodejs npm"
    ]
  } 

}

# --- Static Public IP (Elastic IP) ---
resource "aws_eip" "devbox_eip" {
  instance = aws_instance.devbox.id
  domain   = "vpc"
  tags     = { Name = "${var.ec2_name}-eip" }
}

# --- Outputs ---
output "public_ip" {
  value = aws_eip.devbox_eip.public_ip
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/id_rsa ubuntu@${aws_eip.devbox_eip.public_ip}"
}
