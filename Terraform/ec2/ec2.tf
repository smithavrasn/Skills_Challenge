# Generate SSH Key
resource "tls_private_key" "web" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save the private key to a simple filename in current directory
resource "local_file" "private_key" {
  content         = tls_private_key.web.private_key_pem
  filename        = "web.pem"
  file_permission = "0600"
}

# Create AWS key pair from the generated public key
resource "aws_key_pair" "web" {
  key_name   = "web-key"
  public_key = tls_private_key.web.public_key_openssh
}

# Launch an instance
resource "aws_instance" "webserver" {
  tags = {
    Name = "webserver"
    Description = "An Nginx Webserver on Ubuntu"
  }

  user_data = <<EOF
                  sudo apt get
                  sudo apt install nginx -y
                  systemctl enable nginx
                  systemctl start nginx
              EOF

  ami = "ami-0c101f26f147fa7fd"
  instance_type = var.instance_type
  key_name = aws_key_pair.web.key_name
  vpc_security_group_ids = [ aws_security_group.ssh-access.id ]
}

# Associate Public IP
resource "aws_security_group" "ssh-access" {
    name = "ssh-access"
    description = "Allow ssh access from internet"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}