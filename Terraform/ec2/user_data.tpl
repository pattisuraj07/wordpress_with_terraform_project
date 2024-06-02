#!/bin/bash
sudo su
yum install nginx -y
systemctl enable --now nginx
git clone https://github.com/aakashshinde09/wordpress_with_terraform_project.git
rm -rf /etc/nginx/nginx.conf
cp wordpress_with_terraform_project/Terraform/nginx.conf /etc/nginx/
sed -i "s/\${backend_server_ip}/${eks_worker_node_ip}/" /etc/nginx/nginx.conf  # Replace backend server IP with EKS worker node IP
systemctl restart nginx
