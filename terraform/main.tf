provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.10.0.0/20"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main_vpc"
  }
}

# Subred pública
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.10.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "igw"
  }
}

# Tabla de ruteo
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

resource "aws_route_table_association" "route_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Security Group para el Jump Server
resource "aws_security_group" "sg-jumpserver-linux" {
  name        = "sg-jumpserver-linux"
  description = "Security Group for Jump Server Linux"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Jump"
  }
}

# Security Group para Web Server 1
resource "aws_security_group" "sg-webserver_1_linux" {
  vpc_id      = aws_vpc.main_vpc.id
  name        = "sg-webserver-1-linux"
  description = "Security Group for Web Server Linux 1"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.jump_sg.id]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg-webserver-1-linux"
  }
}

# Security Group para Web Server 2
resource "aws_security_group" "sg-webserver_2_linux" {
  vpc_id      = aws_vpc.main_vpc.id
  name        = "sg-webserver-2-linux"
  description = "Security Group for Web Server Linux 2"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/24"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_block  = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

    tags = {
      Name = "sg-webserver-2-linux"
    }
}

# Security Group para Web Server 3
resource "aws_security_group" "sg-webserver_3_linux" {
  vpc_id      = aws_vpc.main_vpc.id
  name        = "sg-webserver-3-linux"
  description = "Security Group for Web Server Linux 3"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/24"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

    tags = {
      Name = "sg-webserver-3-linux"
    }
}

# Instancia Jump Server
resource "aws_instance" "jumpserver-linux" {
  ami                         = "ami-084568db4383264d4"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups      = [aws_security_group.sg-jumpserver-linux.name]
  key_name                    = "vockey"
  associate_public_ip_address = true

  tags = {
    Name = "jumpserver-linux"
  }
}

resource "aws_instance" "webserver-linux-1" {
  ami                         = "ami-084568db4383264d4"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups      = [aws_security_group.sg-webserver_1_linux.name]
  key_name                    = "vockey"
  associate_public_ip_address = true

  tags = {
    Name = "webserver-linux-1"
  }
}

resource "aws_instance" "webserver-linux-2" {
  ami                         = "ami-084568db4383264d4"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups      = [aws_security_group.sg-webserver_2_linux.name]
  key_name                    = "vockey"
  associate_public_ip_address = true

  tags = {
    Name = "webserver-linux-2"
  }
}

resource "aws_instance" "webserver-linux-3" {
  ami                         = "ami-084568db4383264d4"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups      = [aws_security_group.sg-webserver_3_linux.name]
  key_name                    = "vockey"
  associate_public_ip_address = true

  tags = {
    Name = "webserver-linux-3"
  }
}

#outputs

output "jumpserver-linux_public_ip" {
    value = aws_instance.linux-jumpserver.public_ip
    description = "Public IP of the Linux Jump Server"
}
output "webserver-linux-1_public_ip" {
    value = aws_instance.linux-webserver-1.public_ip
    description = "Public IP of the Linux Web Server 1"
}
output "webserver-linux-2_public_ip" {
    value = aws_instance.webserver-linux-2.public_ip
    description = "Public IP of the Linux Web Server 2"
}
output "webserver-linux-3_public_ip" {
    value = aws_instance.webserver-linux-3.public_ip
    description = "Public IP of the Linux Web Server 3"
}