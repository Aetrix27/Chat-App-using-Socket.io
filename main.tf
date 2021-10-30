provider "aws"{
  region = "us-east-1"
  access_key = "AKIA2E3L4YQVEQA7YRVF"
  secret_key = "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"
}

resource "aws_vpc" "vpc1"{
    cidr_block = "10.0.0.0/26"
    tags = {
        Name = "production-vpc"
    }
   
}
resource "aws_internet_gateway" "gw"{
    vpc_id = aws_vpc.vpc1.id
}

resource "aws_route_table" "first-route-table" {
    vpc_id = aws_vpc.vpc1.id

  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw.id
    }
  route{
      ipv6_cidr_block        = "::/0"
      gateway_id = aws_internet_gateway.gw.id
    }
  

  tags = {
    Name = "Main"
  }
}

resource "aws_route_table" "second-route-table" {
    vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  route{
      ipv6_cidr_block        = "::/0"
      gateway_id = aws_internet_gateway.gw.id
    }

  tags = {
    Name = "Main"
  }
}

resource "aws_security_group" "allow_security" {
  name        = "allow_security"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc1.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
    ingress {
    description      = "SSH"
    from_port        = 2
    to_port          = 2
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress{
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
        //ipv6_cidr_blocks = ["::/0"]
    }
  

  tags = {
    Name = "allow_security"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.first-route-table.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.second-route-table.id
}

resource "aws_subnet" "subnet1"{
    vpc_id = aws_vpc.vpc1.id
    cidr_block = "10.0.0.0/28"
    availability_zone = "us-east-1b"
     tags = {
        Name = "first-zone"
    }
}

resource "aws_subnet" "subnet2"{
    vpc_id = aws_vpc.vpc1.id
    cidr_block = "10.0.0.32/28"
    availability_zone = "us-east-1c"

     tags = {
        Name = "second-zone"
    }
}

resource "aws_network_interface" "network-1" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["10.0.0.4"]
  security_groups = [aws_security_group.allow_security.id]

}

resource "aws_network_interface" "network-2" {
  subnet_id       = aws_subnet.subnet2.id
  private_ips     = ["10.0.0.36"]
  security_groups = [aws_security_group.allow_security.id]

}


resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.network-1.id
  associate_with_private_ip = "10.0.0.4"
  depends_on = [aws_internet_gateway.gw]
     
  
}


resource "aws_eip" "two" {
  vpc                       = true
  network_interface         = aws_network_interface.network-2.id
  associate_with_private_ip = "10.0.0.36"
  depends_on = [aws_internet_gateway.gw]
     
  
}

resource "aws_instance" "web-server-instance1"{
    ami = "ami-02e136e904f3da870"
    instance_type = "t2.micro"
    availability_zone = "us-east-1b"
    key_name = "primary-key"
    subnet_id = aws_subnet.subnet1.id
    vpc_security_group_ids = [aws_security_group.allow_security.id]

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.network-1.id
    }

    user_data = <<-EOF
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo first instance works! > /var/www/html/index.html'
                EOF
    tags = {
        Name = "web-server"
    }

}

resource "aws_instance" "web-server-instance2"{
    ami = "ami-02e136e904f3da870"
    instance_type = "t2.micro"
    availability_zone = "us-east-1c"
    key_name = "primary-key"
    subnet_id = aws_subnet.subnet2.id
    vpc_security_group_ids = [aws_security_group.allow_security.id]


    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.network-2.id
    }

    user_data = <<-EOF
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo second instance works! > /var/www/html/index.htm'
                EOF
    tags = {
        Name = "web-server"
    }

}
