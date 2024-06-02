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

  # Restrict inbound and outbound traffic based on your application's needs
  # (consider removing all traffic rules and adding specific ones)
  # Example: Allow inbound web traffic (port 80) from anywhere
  # ingress {
  #   from_port = 80
  #   to_port = 80
  #   protocol = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  # egress {
  #   from_port = 0
  #   to_port = 0
  #   protocol = "-1"
  #   cidr_blocks = [var.cidr_block]
  # }
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

resource "aws_eip" "eks_node_eip" {
  # This might not be necessary if worker nodes already have public IPs
  instance = aws_instance.proxy_instance.id
}

output "eks_elastic_ip" {
  value = aws_eip.eks_node_eip.public_ip  # Output might be empty if not allocated
}
