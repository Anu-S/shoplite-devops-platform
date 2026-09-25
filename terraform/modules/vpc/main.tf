# VPC Module
# ----------
# This creates the network "container" everything else will live inside:
# public subnets (for anything that needs a direct internet route, like a
# load balancer) and private subnets (for anything that shouldn't be
# directly internet-facing, like application pods) — a standard,
# interview-expected pattern.
#
# COST NOTE: this version deliberately has NO NAT Gateway, to stay 100%
# free-tier. That means the private subnets exist and are correctly
# structured, but resources placed in them won't have outbound internet
# access yet (e.g. couldn't pull a Docker image from a private subnet).
# We'll add a NAT Gateway back in Week 5/6 when EKS workloads actually
# need it — and only run it for the sessions we're using it, since it's
# billed hourly (~$0.045/hr, not free-tier eligible).

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "AZs to spread subnets across, for high availability"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

variable "project_name" {
  description = "Used to prefix/tag all resources this module creates"
  type        = string
  default     = "shoplite"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public subnets — one per AZ. Resources here (like a load balancer) get
# a direct route to the internet gateway. This part is fully free.
resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name                     = "${var.project_name}-public-${var.availability_zones[count.index]}"
    "kubernetes.io/role/elb" = "1" # tells EKS this subnet can host public load balancers
  }
}

# Private subnets — one per AZ. This is where EKS worker nodes / pods
# will eventually run. No NAT Gateway attached yet (see cost note above),
# so these currently have no outbound internet route — that's expected
# and fine at this stage; we're building the shape of the network first.
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name                              = "${var.project_name}-private-${var.availability_zones[count.index]}"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# Private route table exists (for structure/consistency) but has no
# internet route yet — no NAT Gateway means no 0.0.0.0/0 route here.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
