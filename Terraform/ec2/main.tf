resource "aws_key_pair" "akash_key" {
  key_name = "akash-key"
  public_key = file("~/.ssh/authorized_keys")
}

resource "aws_security_group" "proxy_sg" {
name = "proxy-sg"
description = "Security group for our proxy"

# inbound rule for ssh
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  # inbound rule for All TCP
  ingress {
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = [var.cidr_block]
  }
  

  # outbound rule for all traffic
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ var.cidr_block ]


  }
}
resource "aws_instance" "proxy_instance" {
  ami                    = var.this_instance_ami
  instance_type          = var.this_instance_type
  key_name               = aws_key_pair.akash_key.key_name
  vpc_security_group_ids = [aws_security_group.proxy_sg.id]

  # Pass the EKS worker node IP address to the EC2 instance
  user_data = templatefile("${path.module}/user_data.tpl", {
    eks_worker_node_ip = module.eks.eks_worker_node_ip
  })

  tags = {
    Name = "proxy-instance"
  }
}

resource "aws_eip" "eks_node_eip" {
  instance = aws_instance.proxy_instance.id
}

output "elastic_ip" {
  value = aws_eip.eks_node_eip.public_ip
}

module "eks" {
  source = "../eks"
}
