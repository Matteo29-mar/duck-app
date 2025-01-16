provider "aws" {
  region = "eu-west-1"
}

resource "aws_instance" "ec2_with_docker" {
  ami           = "ami-01f5f2e96f603b15b" 
  instance_type = "t2.micro" 
  key_name      = "terraform" 
  tags = {
    Name = "EC2-with-Docker"
  }

  # Installazione di Docker e download dell'immagine
  user_data = <<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y docker
    sudo service docker start
    sudo usermod -aG docker ec2-user
    docker pull web-app-flask:latest
    docker run -d -p 5000:5000 matteo29mar/web-app-flask:latest
  EOF

  # Assicurati che l'istanza possa comunicare attraverso le porte necessarie
  vpc_security_group_ids = [aws_security_group.docker_sg.id]

  # Opzionale: Se desideri utilizzare un EIP
  associate_public_ip_address = true
}

# Gruppo di sicurezza per l'accesso SSH e Docker
resource "aws_security_group" "docker_sg" {
  name_prefix = "docker-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Accesso SSH da ovunque (modifica per maggiore sicurezza)
  }

  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Accesso HTTP 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "instance_public_ip" {
  value = aws_instance.ec2_with_docker.public_ip
}
