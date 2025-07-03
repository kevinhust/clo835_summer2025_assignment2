# CLO835 Assignment Main Terraform Configuration

provider "aws" {
  region = var.region
}

# VPC
resource "aws_vpc" "clo835_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "CLO835"
  }
}

# Public Subnet
resource "aws_subnet" "clo835_public_subnet" {
  vpc_id                  = aws_vpc.clo835_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "CLO835-public-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "clo835_igw" {
  vpc_id = aws_vpc.clo835_vpc.id
  tags = {
    Name = "CLO835-igw"
  }
}

# Route Table
resource "aws_route_table" "clo835_rt" {
  vpc_id = aws_vpc.clo835_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.clo835_igw.id
  }
  tags = {
    Name = "CLO835-rt"
  }
}

resource "aws_route_table_association" "clo835_rta" {
  subnet_id      = aws_subnet.clo835_public_subnet.id
  route_table_id = aws_route_table.clo835_rt.id
}

# Security Group
resource "aws_security_group" "clo835_sg" {
  name        = "CLO835-sg"
  description = "Allow web and SSH traffic"
  vpc_id      = aws_vpc.clo835_vpc.id

  ingress {
    description = "Allow HTTP for webapp blue"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTP for webapp pink"
    from_port   = 8082
    to_port     = 8082
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow HTTP for webapp lime"
    from_port   = 8083
    to_port     = 8083
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow ICMP (ping)"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow K8s NodePort services (30000-32767)"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow K8s API server access"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "CLO835-sg"
  }
}

# ECR Repositories
resource "aws_ecr_repository" "clo835_ecr" {
  for_each = toset(var.ecr_repo_names)
  name     = "clo835ecr-${each.key}"
}

# Data source for existing key pair
# (Assumes CLO835A1 key pair already exists in AWS)
data "aws_key_pair" "clo835_key" {
  key_name = var.key_name
}

# Data source for existing IAM instance profile
# (Assumes LabProfile instance profile already exists in AWS)
data "aws_iam_instance_profile" "LabProfile_profile" {
  name = var.iam_instance_profile
}

# EC2 Instance
resource "aws_instance" "clo835_ec2" {
  ami                         = var.ec2_ami
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.clo835_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.clo835_sg.id]
  key_name                    = data.aws_key_pair.clo835_key.key_name
  iam_instance_profile        = data.aws_iam_instance_profile.LabProfile_profile.name
  associate_public_ip_address = true
  
  # Root block device with 20GB storage
  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }
  
  user_data = <<-EOF
    #!/bin/bash
    dnf update -y

    # Install Docker
    dnf install -y docker
    systemctl start docker
    usermod -a -G docker ec2-user
    systemctl enable docker

    # Install docker-compose
    dnf install -y docker-compose-plugin

    # Install git
    dnf install -y git

    # Install awscli
    dnf install -y awscli

    # Install mysql client
    dnf install -y mysql

    # Make docker compose command available
    ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose || true

    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl

    # Install kind
    [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
  EOF

  tags = {
    Name = "CLO835-ec2"
  }
}
