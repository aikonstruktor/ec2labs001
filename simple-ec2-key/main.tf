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

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # Uses variable for security
  }

  ingress {
    from_port   = 8090
    to_port     = 8090
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # Uses variable for security
  }

  ingress {
    description = "ICMP within cluster"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
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
  key_name   = "ec2-ssh-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# --- EC2 Instance ---
resource "aws_instance" "devbox" {
  for_each = {
    for idx, node in var.ec2_nodes :
    idx => node
  }

  ami                    = each.value.ami_id
  instance_type          = each.value.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ssh_access.id]
  key_name               = aws_key_pair.deployer.key_name

  root_block_device {
    volume_size = 40          # 🔥 increase from default (~8GB)
    volume_type = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name    = each.value.name
    SSHUser = each.value.ami_user
  }

  connection {
    type        = "ssh"
    user        = each.value.ami_user
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "~/.ssh/id_ed25519_xe"
    destination = "/home/${each.value.ami_user}/.ssh/id_ed25519_xe"
  }

  provisioner "file" {
    source      = "~/.ssh/id_ed25519_ai"
    destination = "/home/${each.value.ami_user}/.ssh/id_ed25519_ai"
  }

  provisioner "file" {
    source      = "./${each.value.ami_user}.sh"
    destination = "/home/${each.value.ami_user}/${each.value.ami_user}.sh"
  }

  provisioner "file" {
    source      = "./tmux.conf"
    destination = "/home/${each.value.ami_user}/tmux.conf"
  }

   provisioner "file" {
    source      = "./prompt.sh"
    destination = "/home/${each.value.ami_user}/prompt.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 700 /home/${each.value.ami_user}/.ssh",
      "chmod 600 /home/${each.value.ami_user}/.ssh/id_ed25519_xe",
      "chmod 600 /home/${each.value.ami_user}/.ssh/id_ed25519_ai",
      "chown -R ${each.value.ami_user}:${each.value.ami_user} /home/${each.value.ami_user}/.ssh",
      "chmod +x /home/${each.value.ami_user}/${each.value.ami_user}.sh",
      "/home/${each.value.ami_user}/${each.value.ami_user}.sh",
      "mkdir -p /home/${each.value.ami_user}/.config/tmux",
      "mkdir -p /home/${each.value.ami_user}/.config/bash",
      "mv /home/${each.value.ami_user}/prompt.sh /home/${each.value.ami_user}/.config/bash/prompt.sh",
      "mv /home/${each.value.ami_user}/tmux.conf /home/${each.value.ami_user}/.config/tmux/tmux.conf",
    ]
  }
}


# --- Static Public IP (Elastic IP) ---
resource "aws_eip" "devbox_eip" {
  for_each = aws_instance.devbox

  instance = each.value.id
  domain   = "vpc"

  tags = {
    Name = "${each.value.tags.Name}-eip"
  }
}


# --- Outputs ---
output "public_ips" {
  value = {
    for k, eip in aws_eip.devbox_eip :
    aws_instance.devbox[k].tags.Name => eip.public_ip
  }
}

output "ssh_commands" {
  value = {
    for k, inst in aws_instance.devbox :
    inst.tags.Name => "ssh -i ~/.ssh/id_rsa ${inst.tags.SSHUser}@${aws_eip.devbox_eip[k].public_ip}"
  }
}

