region = "us-east-1"
vpc_cidr = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
ecr_repo_names = ["webapp", "mysql"]
ec2_ami = "ami-02457590d33d576c3"
ec2_instance_type = "t3.medium"  # 4GB RAM for optimal KIND cluster
key_name = "CLO835A1"
iam_instance_profile = "LabProfile"
