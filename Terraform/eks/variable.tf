variable "vpc" {
  type = bool
}

variable "subnet1_val" {
  type = string
}

variable "subnet2_val" {
  type = string
}

variable "cidr_blocks_eks" {
  type = string
}

variable "eks_cluster_name" {
  type = string
}

variable "eks_role" {
  type = string
}

variable "node_group_name" {
  type = string
}

variable "eks_node_group_role" {
  type = string
}

variable "region" {
  type = string
}
