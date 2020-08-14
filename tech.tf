provider "aws" {
  region  = "us-east-1"
  access_key = "your_access_key"
  secret_key = "your_secret_key"
}


resource "aws_vpc" "lamp-vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "lamp_vpc"
  }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.lamp-vpc.id

  tags = {
    Name = "d3vgateway"
  } 
}

resource "aws_route_table" "lamp-route-table" {
  vpc_id = aws_vpc.lamp-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "d3vroutetable"
  }
}

resource "aws_subnet" "lamp-vpc-subnet" {
  vpc_id     = aws_vpc.lamp-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

tags = {
   Name = "lamp-vpc-subnet"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id         = aws_subnet.lamp-vpc-subnet.id
  route_table_id    = aws_route_table.lamp-route-table.id
}

resource "aws_security_group" "allow_web_traffic" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.lamp-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

ingress {
    description = "MySql"
    from_port   = 3306
    to_port     = 3306
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
    Name = "allow_web"
  }
}

resource "aws_network_interface" "d3v-web-server" {
  subnet_id       = aws_subnet.lamp-vpc-subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web_traffic.id]

}

resource "aws_eip" "d3v-eip" {
  vpc                       = true
  network_interface         = aws_network_interface.d3v-web-server.id
  #associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}


resource "aws_instance" "d3vinstance" {
  ami           = "ami-0bcc094591f354be2"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "main-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.d3v-web-server.id
  }
   user_data = <<-EOF
                #!/bin/bash
                 sudo apt update -y
                 sudo apt install apache2 -y
                 sudo systemctl start apache2
                 sudo bash -c 'echo Welcome to D3V Technology Solutions > /var/www/html/index.html'
                 sudo apt install -y mysql php php-mysql
                 EOF
               

  tags = {
    Name = "D3Vinstance"
  }
}

resource "aws_db_instance" "d3vdatabase" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "indravesh"
  password             = "indr1234"
  port = 3306
}

