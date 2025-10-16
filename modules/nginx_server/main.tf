resource "aws_instance" "server" {
  ami           = "ami-070e0d4707168fc07"
  instance_type = var.instance_type
  tags = {
    Name = "TestWebServer"
  }

  user_data = <<EOF
#!/bin/bash
amazon-linux-extras install -y nginx1
systemctl start nginx
EOF
}
