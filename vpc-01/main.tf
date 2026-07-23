##########################
########### VPC ##########
##########################

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = merge(
    {
      Name = var.environment_name
    },
    var.tags
  )
}

#####################################
####### Public Subnets ##############
#####################################

resource "aws_subnet" "public_subnets" {
  for_each = var.public_subnets

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name      = "${var.environment_name}-${each.key}"
      createdBy = var.environment_name
    },
    var.public_subnet_tags,
    var.tags
  )
}

############################################
### Internet Gateway #######################
############################################

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    {
      Name = "${var.environment_name}-igw"
    },
    var.tags
  )
}

##

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(
    {
      Name = "${var.environment_name}-nat-eip"
    },
    var.tags
  )

  depends_on = [aws_internet_gateway.gw]
}


####


resource "aws_nat_gateway" "nat" {
  count = var.enable_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat.id
  subnet_id     = values(aws_subnet.public_subnets)[0].id
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

  tags = merge(
    {
      Name      = "${var.environment_name}-public-rt"
      createdBy = var.environment_name
    },
    var.tags
  )
}

############################################
### Associate Public Subnets with Route Table
############################################

resource "aws_route_table_association" "public_subnet_routes_assn" {
  for_each = aws_subnet.public_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_routing.id
}

#####################################
####### Private Subnets #############
#####################################

resource "aws_subnet" "private_subnets" {
  for_each = var.private_subnets

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = false

  tags = merge(
    {
      Name      = "${var.environment_name}-${each.key}"
      createdBy = var.environment_name
    },
    var.private_subnet_tags,
    var.tags
  )
}

############################################
### Private Route Table ####################
############################################

resource "aws_route_table" "private_routing" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = merge(
    {
      Name      = "${var.environment_name}-private-rt"
      createdBy = var.environment_name
    },
    var.tags
  )
}



############################################
### Associate Private Subnets with Route Table
############################################

resource "aws_route_table_association" "private_subnet_routes_assn" {
  for_each = aws_subnet.private_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_routing.id
}

#############################
######## Outputs ############
#############################

output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.vpc.id
}

output "public_subnets" {
  description = "The IDs of the public subnets"
  value       = [for subnet in aws_subnet.public_subnets : subnet.id]
}

output "private_subnets" {
  description = "The IDs of the private subnets"
  value       = [for subnet in aws_subnet.private_subnets : subnet.id]
}
