
```
variable "instance_types" {
  description = "A map of instance types and their counts"
  type        = map(number)
  default     = {}
}

variable "ami" {
  description = "The AMI ID for the EC2 instance"
  type        = string
}

variable "subnet_id" {
  description = "The subnet ID for the instance"
  type        = string
}

variable "environment_name" {
  description = "Environment name to be used in instance tags"
  type        = string
}

resource "aws_instance" "example" {
  for_each             = var.instance_types
  ami                  = var.ami
  instance_type        = each.key
  subnet_id            = var.subnet_id
  availability_zone    = data.aws_subnet.selected.availability_zone

  tags = {
    Name        = "EC2-${each.key}-${lookup(local.env_suffix_map, var.environment_name, "env")}"
    Environment = var.environment_name
  }
}

data "aws_subnet" "selected" {
  id = var.subnet_id
}

locals {
  # You can customize the mapping of environment names to suffixes
  env_suffix_map = {
    "gl-dev"     = "dev"
    "gl-preprod" = "preprod"
    "gl-prod"    = "prod"
  }
}

output "instance_ids" {
  description = "The IDs of the created EC2 instances"
  value       = { for k, v in aws_instance.example : k => v.id }
}



```
