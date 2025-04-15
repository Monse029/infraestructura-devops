# --- Proveedor de AWS ---
provider "aws" {
  region = "us-east-1"
}

# --- Red VPC Principal ---
resource "aws_vpc" "vpc_principal" {
  cidr_block           = "10.10.0.0/20"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Red-VPC-Infra"
  }
}

# --- Subred Pública Principal ---
resource "aws_subnet" "subred_publica" {
  vpc_id                  = aws_vpc.vpc_principal.id
  cidr_block              = "10.10.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "Subred-Acceso-Publico"
  }
}

# --- Gateway de Internet ---
resource "aws_internet_gateway" "internet_gw" {
  vpc_id = aws_vpc.vpc_principal.id

  tags = {
    Name = "Gateway-Internet"
  }
}

# --- Tabla de Rutas Pública ---
resource "aws_route_table" "tabla_rutas_publica" {
  vpc_id = aws_vpc.vpc_principal.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gw.id
  }

  tags = {
    Name = "Tabla-Rutas-Publica"
  }
}

# --- Asociación Tabla/Subred ---
resource "aws_route_table_association" "asociacion_rutas" {
  subnet_id      = aws_subnet.subred_publica.id
  route_table_id = aws_route_table.tabla_rutas_publica.id
}

# --- SG para Servidor de Salto ---
resource "aws_security_group" "sg_salto" {
  name        = "SG-Salto"
  description = "Permite SSH desde cualquier IP pública"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acceso SSH global"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-Servidor-Salto"
  }
}

# --- SG para Web Servers ---
resource "aws_security_group" "sg_webserver" {
  name        = "SG-WebServers"
  description = "Permite HTTP público y SSH desde el servidor de salto"
  vpc_id      = aws_vpc.vpc_principal.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Acceso HTTP publico"
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_salto.id]
    description     = "SSH desde Servidor de Salto"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG-WebServers"
  }
}

# --- Instancia EC2 Servidor de Salto ---
resource "aws_instance" "servidor_salto" {
  ami                         = "ami-00a929b66ed6e0de6"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subred_publica.id
  vpc_security_group_ids      = [aws_security_group.sg_salto.id]
  associate_public_ip_address = true
  key_name                    = "vockey"

  tags = {
    Name = "Servidor-Salto"
  }
}

# --- Múltiples Instancias Web ---
resource "aws_instance" "instancias_web" {
  count                       = 3
  ami                         = "ami-00a929b66ed6e0de6"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.subred_publica.id
  vpc_security_group_ids      = [aws_security_group.sg_webserver.id]
  associate_public_ip_address = true
  key_name                    = "vockey"

  tags = {
    Name = "Servidor-Web-${count.index + 1}"
  }
}

# --- Salidas ---
output "ip_publica_salto" {
  value       = aws_instance.servidor_salto.public_ip
  description = "IP pública del Servidor de Salto"
}

output "ips_publicas_web" {
  value       = aws_instance.instancias_web[*].public_ip
  description = "IPs públicas de los servidores web"
}

