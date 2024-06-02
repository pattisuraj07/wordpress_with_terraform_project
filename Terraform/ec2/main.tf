resource "aws_key_pair" "akash_key" {
  key_name = "akash-key"
  public_key = file("~/.ssh/authorized_keys")
}

resource "aws_security_group" "proxy_sg" {
  name = "proxy-sg"
  description = "Security Group for our proxy"

  # Inbound rule for SSH (consider restricting source IP)
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "tcp"
    cidr_blocks = [var.cidr_block]
  }

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.cidr_block]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [var.cidr_block]
  }
}

resource "aws_instance" "proxy_instance" {
  ami = var.this_instance_ami
  instance_type = var.this_instance_type
  key_name = aws_key_pair.akash_key.key_name
  vpc_security_group_ids = [aws_security_group.proxy_sg.id]

  # Pass the EKS worker node's PUBLIC IP address to the EC2 instance
  user_data = templatefile("${path.module}/user_data.tpl", {
    # Assuming the eks module provides an attribute for public IP (verify the name)
    eks_worker_node_public_ip = module.eks.worker_node_public_ip
  })

  tags = {
    Name = "proxy-instance"
  }
}


