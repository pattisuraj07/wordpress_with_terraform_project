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
  ami = var.this_instance_ami
  instance_type = var.this_instance_type
  key_name = aws_key_pair.akash_key.key_name
  vpc_security_group_ids = [aws_security_group.proxy_sg.id]

# This is same when we were using user data while creating instance manually
  user_data = <<-EOF
              #!/bin/bash
              sudo su
              yum install nginx -y
              systemctl enable --now nginx
              git clone https://github.com/aakashshinde09/wordpress-site.git
              rm -rf /etc/nginx/nginx.conf
              cp wordpress-site/Terraform/nginx.conf /etc/nginx/
              sed -i "s/\${backend_server_ip}/${var.backend_server_ip}/" /etc/nginx/nginx.conf
              systemctl restart nginx
              EOF

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