
```
##########################
########### VPC ##########
##########################

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
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
  cidr_block              = each.value
  availability_zone       = element(data.aws_availability_zones.available.names,
                            index(keys(var.public_subnets), each.key))
  map_public_ip_on_launch = true

  tags = {
    Name      = "${var.environment_name}-${each.key}"
    createdBy = var.environment_name
  }
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
  cidr_block              = each.value
  availability_zone       = element(data.aws_availability_zones.available.names, index(keys(var.private_subnets), each.key))
  map_public_ip_on_launch = false

  tags = {
    Name      = "${var.environment_name}-${each.key}"
    createdBy = var.environment_name
  }
}


############################################
### Private Route Table ####################
############################################

resource "aws_route_table" "private_routing" {
  vpc_id = aws_vpc.vpc.id

  # Route everything through NAT Gateway
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
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



/*

############################################
### NAT Gateway & Elastic IP ################
############################################

resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets["public-1a"].id  # Ensure "public-1" exists in var.public_subnets

  tags = {
    Name = "${var.environment_name}-nat-gateway"
  }
}


*/



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



data "aws_availability_zones" "available" {}

module "vpc" {
  source               = "../modules/vpc"
  environment_name     = var.environment_name
  enable_dns_hostnames = true
  enable_nat_gateway   = true
  vpc_cidr             = var.vpc_cidr
  azs                  = data.aws_availability_zones.available.names
  public_subnets       = var.public_subnets
  private_subnets      = var.private_subnets

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.environment_name}" = "shared"
    "kubernetes.io/role/elb"                         = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.environment_name}" = "shared"
    "kubernetes.io/role/internal-elb"              = "1"
  }
}


```
