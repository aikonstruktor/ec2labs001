provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}

# Use var.vpc_cidr and var.vpc_name
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.vpc_name}-igw" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1) # Dynamically creates 10.0.1.0/24
  map_public_ip_on_launch = true
}

# Standard SSM Role (No changes needed here)
resource "aws_iam_role" "ssm_role" {
  name = "${var.ec2_name}-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.ec2_name}-profile"
  role = aws_iam_role.ssm_role.name
}

# Use var.ec2_name
resource "aws_instance" "devbox" {
  ami                  = "ami-0ebfd15658b045627" # Amazon Linux 2023
  instance_type        = "t3.micro"
  subnet_id            = aws_subnet.public.id
  iam_instance_profile = aws_iam_instance_profile.profile.name
  
  tags = {
    Name = var.ec2_name
  }
}
