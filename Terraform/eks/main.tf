# Your eks module configuration...

data "aws_iam_role" "eks_node_group_role" {
  name = var.eks_node_group_role
}


data "aws_vpc" "default" {
  default = var.vpc
}

data "aws_subnet" "subnet1" {
  filter {
    name   = "availabilityZone"
    values = [var.subnet1_val]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "subnet2" {
  filter {
    name   = "availabilityZone"
    values = [var.subnet2_val]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "eks_sg" {
  vpc_id      = data.aws_vpc.default.id
  name        = "eks-sg"
  description = "Security Group for the eks cluster"

  # inbound rule for All Traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_blocks_eks]
  }

  # inbound rule for All TCP
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = [var.cidr_blocks_eks]
  }

  # outbound rule for All Traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_blocks_eks]
  }
}



resource "aws_eks_cluster" "eks_cluster" {
  name     = var.eks_cluster_name
  role_arn = data.aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids         = [data.aws_subnet.subnet1.id, data.aws_subnet.subnet2.id]
    security_group_ids = [aws_security_group.eks_sg.id]
  }
}

data "aws_iam_role" "eks_role" {
  name = var.eks_role  
}


resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = var.node_group_name
  node_role_arn   = data.aws_iam_role.eks_node_group_role.arn
  subnet_ids      = [data.aws_subnet.subnet1.id, data.aws_subnet.subnet2.id]
  
  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  tags = {
    Name = var.node_group_name
  }
}
