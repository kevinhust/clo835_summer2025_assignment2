# clo835tf

This repository contains the Terraform code for deploying the infrastructure required for **CLO835 Assignment1**.

**Author/GitHub:** [kevinhust](https://github.com/kevinhust)

**Purpose:** This repository provides dedicated Terraform code for CLO835 Assignment1, automating the deployment of AWS ECR, EC2, and related resources.

---

## Features

- Deploys a custom VPC, public subnet, and internet gateway
- Creates security groups for web and SSH access
- Provisions Amazon ECR repositories for webapp and MySQL images
- Launches an EC2 instance in a public subnet with required IAM profile
- Outputs all key resource information for further use

---

## Prerequisites

- AWS account with sufficient permissions
- Existing EC2 Key Pair (default: `CLO835A1`)
- Existing IAM Instance Profile (default: `LabProfile`)
- Terraform v1.0+ installed locally

---

## Usage

1. **Clone this repository**
   ```bash
   git clone https://github.com/kevinhust/clo835tf.git
   cd clo835tf
   ```

2. **Configure variables**

   - Default variables are set in `terraform.tfvars`. You can edit this file to customize your deployment:
     ```hcl
     region             = "us-east-1"
     vpc_cidr           = "10.0.0.0/16"
     public_subnet_cidr = "10.0.1.0/24"
     ecr_repo_names     = ["webapp", "mysql"]
     ec2_ami            = "ami-02457590d33d576c3"
     ec2_instance_type  = "t3.micro"
     key_name           = "CLO835A1"
     iam_instance_profile = "LabProfile"
     ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Review the plan**
   ```bash
   terraform plan
   ```

5. **Apply the configuration**
   ```bash
   terraform apply
   ```
   - Type `yes` to confirm and deploy

6. **Retrieve output information**
   - After deployment, Terraform will output:
     - VPC ID
     - Public Subnet ID
     - ECR repository URLs
     - EC2 Public IP
     - Security Group ID

---

## Clean Up

To destroy all resources created by this Terraform code:
```bash
terraform destroy
```

---

## Notes

- **Do NOT commit the `.terraform` directory or Terraform state files to your GitHub repository.**
- This code is for CLO835 Assignment1 purposes only.
- For full assignment functionality, use this infrastructure code together with your application code and GitHub Actions workflow (for building and pushing Docker images to ECR, etc.).

---

## References

- [Assignment1 Application Repository](https://github.com/codesavvysm/clo835_summer2025_assignment1)
- [AWS Terraform Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [CLO835 Course Resources](https://catalog.us-east-1.prod.workshops.aws/workshops/8c9036a7-7564-434c-b558-3588754e21f5/en-US/)
