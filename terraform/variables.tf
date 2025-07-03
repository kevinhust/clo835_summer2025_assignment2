# Variables for CLO835 Assignment Infrastructure

variable "region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "ecr_repo_names" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = ["webapp", "mysql"]
}

variable "ec2_ami" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-02457590d33d576c3"
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"  # 4GB RAM for optimal KIND cluster performance
}

variable "key_name" {
  description = "Name of the existing EC2 Key Pair"
  type        = string
  default     = "CLO835A1"
}

variable "iam_instance_profile" {
  description = "Name of the existing IAM instance profile for EC2"
  type        = string
  default     = "LabProfile"
}
