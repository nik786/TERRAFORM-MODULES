

variable "cidr" {
  type = string
}

variable "environment_name" {
  type = string
}

variable "public_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "private_subnets" {
  type = map(object({
    cidr = string
    az   = string
  }))
}

variable "public_subnet_tags" {
  type    = map(string)
  default = {}
}




##########################
########### VPC ##########
##########################

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name = var.environment_name
  }
}

#############################
### Availability Zones Data #
#############################
data "aws_availability_zones" "available" {}

############################
#### Public Subnets ########
############################

resource "aws_subnet" "public_subnets" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge({
    Name      = "${var.environment_name}-${each.key}"
    createdBy = var.environment_name
  }, var.public_subnet_tags)
}

##################################
### Public Route Table ###########
##################################

resource "aws_route_table" "public_routing" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name      = "${var.environment_name}-route-table"
    createdBy = var.environment_name
  }
}

############################################
### Associate Public Subnets with Route Table
############################################

resource "aws_route_table_association" "public_subnet_routes_assn" {
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_routing.id
}

############################################
### Internet Gateway for Public Subnet #####
############################################

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.environment_name}-igw"
  }
}






#####################################
####### Private Subnets #############
#####################################

resource "aws_subnet" "private_subnets" {
  for_each                = var.private_subnets
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge({
    Name      = "${var.environment_name}-${each.key}"
    createdBy = var.environment_name
  }, var.private_subnet_tags)
}


############################################
### Private Route Table ####################
############################################

resource "aws_route_table" "private_routing" {
  vpc_id = aws_vpc.vpc.id


  route {
    cidr_block     = "0.0.0.0/0"
   
  }

  tags = {
    Name      = "${var.environment_name}-private-route-table"
    createdBy = var.environment_name
  }
}

############################################
### Associate Private Subnets with Route Table
############################################

resource "aws_route_table_association" "private_subnet_routes_assn" {
  for_each       = aws_subnet.private_subnets
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_routing.id
}







##################### Output section
output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "The ID of the VPC"
}

output "public_subnets" {
  value       = [for subnet in aws_subnet.public_subnets : subnet.id]
  description = "The IDs of the public subnets"
}

output "private_subnets" {
  value       = [for subnet in aws_subnet.private_subnets : subnet.id]
  description = "The IDs of the private subnets"
}

