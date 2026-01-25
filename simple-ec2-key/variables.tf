variable "aws_region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "The AWS CLI profile to use for authentication"
  type        = string
  default     = "default"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "The name tag for the VPC"
  type        = string
  default     = "agents-dev-vpc"
}

variable "ec2_name" {
  description = "The name tag for the EC2 instance"
  type        = string
  default     = "devbox-001"
}

variable "ec2_ami_id" {
  description = "The ami_id for the EC2 instance"
  type        = string
  default     = "ami-0ebfd15658b045627" # Amazon Linux 2023
}
variable "my_ip" {
  description = "Your public IP address for secure SSH access (e.g., 1.2.3.4/32)"
  type        = string
  # No default value here. You must set your IP in terraform.tfvars for safety!
}