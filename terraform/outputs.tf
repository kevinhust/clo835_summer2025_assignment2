# Outputs for CLO835 Assignment Infrastructure

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.clo835_vpc.id
}

output "public_subnet_id" {
  description = "The ID of the public subnet"
  value       = aws_subnet.clo835_public_subnet.id
}

output "ecr_repo_urls" {
  description = "ECR repository URLs"
  value       = [for repo in aws_ecr_repository.clo835_ecr : repo.repository_url]
}

output "ec2_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.clo835_ec2.public_ip
}

output "security_group_id" {
  description = "ID of the security group attached to EC2"
  value       = aws_security_group.clo835_sg.id
}
