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
  description = "Security Group for the EKS cluster"

  # Inbound rule for all traffic
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_blocks_eks]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "tcp"
    cidr_blocks = [var.cidr_blocks_eks]
  }

  # Outbound rule for all traffic
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
    max_size     = 10
    min_size     = 1
  }

  instance_types = ["t3.large"]
  capacity_type  = "ON_DEMAND"
}

# Retrieve the Auto Scaling Group associated with the node group
data "aws_autoscaling_groups" "asg" {
  filter {
    name = "tag:eks:nodegroup-name"
    values = [aws_eks_node_group.eks_node_group.node_group_name]
  }
}

# Define a static map to hold instance names
variable "instance_map" {
  type = map(string)
  default = {}
}

# Retrieve the instances in the Auto Scaling Group
data "aws_instance" "eks_nodes" {
  for_each = var.instance_map

  filter {
    name = "tag:aws:autoscaling:groupName"
    values = [each.value]
  }
}

# Output the public IP addresses of the instances
output "eks_node_public_ips" {
  value = [for instance in data.aws_instance.eks_nodes : instance.public_ip]
}


# Adding cluster add-ons separately
resource "aws_eks_addon" "coredns" {
  cluster_name   = aws_eks_cluster.eks_cluster.name
  addon_name     = "coredns"
  addon_version  = "v1.11.1-eksbuild.4"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name   = aws_eks_cluster.eks_cluster.name
  addon_name     = "kube-proxy"
  addon_version  = "v1.29.0-eksbuild.1"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name   = aws_eks_cluster.eks_cluster.name
  addon_name     = "vpc-cni"
  addon_version  = "v1.16.0-eksbuild.1"
}

resource "aws_eks_addon" "eks_pod_identity_agent" {
  cluster_name   = aws_eks_cluster.eks_cluster.name
  addon_name     = "eks-pod-identity-agent"
  addon_version  = "v1.2.0-eksbuild.1"
}

# # Adding necessary tags
# resource "aws_ec2_tag" "environment_tag" {
#   resource_id = aws_eks_cluster.eks_cluster.id
#   key         = "Environment"
#   value       = "dev"
# }

# resource "aws_ec2_tag" "terraform_tag" {
#   resource_id = aws_eks_cluster.eks_cluster.id
#   key         = "Terraform"
#   value       = "true"
# }

# Enable cluster creator admin permissions
resource "aws_eks_cluster_auth" "cluster_auth" {
  name             = aws_eks_cluster.eks_cluster.name
  enable           = true
  cluster_name     = aws_eks_cluster.eks_cluster.name
  client_id        = "sts.amazonaws.com"
  user_name        = "system:node:{{EC2PrivateDNSName}}"
  groups           = ["system:masters"]
  lifecycle {
    ignore_changes = [client_id, user_name, groups]
  }
}

# Add access permissions
resource "aws_eks_cluster_extension" "example" {
  cluster_name = aws_eks_cluster.eks_cluster.name

  selector {
    namespace = "default"
  }

  client_request_token = "example"
  request_type         = "AssociateIAMOIDCIdentityProviderConfig"
  response_type        = "AssociateIAMOIDCIdentityProviderConfigResponse"
  version              = "v1beta1"
}