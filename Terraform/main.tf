provider "aws" {
  region = "us-east-1"
}

module "eks" {
  source = "./eks"
  vpc = true
  subnet1_val = "us-east-1a"
  subnet2_val = "us-east-1b"
  cidr_blocks_eks = "0.0.0.0/0"
  eks_cluster_name = "my-cluster"
  eks_role = "EKS-Role"
  node_group_name = "my-node"
  eks_node_group_role = "Node-role"
  region = "us-east-1"
}

output "elastic_ip" {
  value = module.ec2.elastic_ip
}
module "ec2" {
  source = "./ec2"
  this_instance_ami = "ami-00beae93a2d981137"
  this_instance_type = "t2.micro"
  cidr_block = "0.0.0.0/0"
  eks_node_public_ips  = module.ec2.elastic_ip
}
