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
  key_name = var.key_name
  vpc_security_group_ids = [aws_security_group.proxy_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo su
              yum install nginx -y
              systemctl enable --now nginx
              yum install git -y
              git clone https://github.com/aakashshinde09/wordpress-site.git
              EOF

  tags = {
    Name = "proxy-instance"
  }
}


