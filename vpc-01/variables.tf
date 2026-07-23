



variable "environment_name" {
  description = "Environment name for tagging"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}



variable "public_subnets" {
  description = "List of CIDR blocks for public subnets"
  type        = map(string)
}

variable "private_subnets" {
  description = "List of CIDR blocks for private subnets"
  type        = map(string)
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_nat_gateway" {
  description = "Enable or disable NAT Gateway"
  type        = bool
  default     = true
}


variable "public_subnet_tags" {
  description = "Tags for public subnets"
  type        = map(string)
  default     = {} # Allows flexibility if not defined in `dev.tfvars`
}

variable "private_subnet_tags" {
  description = "Tags for private subnets"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}

