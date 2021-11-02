provider "aws"{
  region = "us-east-1"
  access_key = var.a_key
  secret_key = var.s_key
}

variable "a_key" {
    type        = string
}

variable "s_key" {
    type        = string
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
/*
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
*/

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
    from_port        = 22
    to_port          = 22
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
  route_table_id = aws_route_table.first-route-table.id
}

resource "aws_subnet" "subnet1"{
    vpc_id = aws_vpc.vpc1.id
    cidr_block = "10.0.0.0/28"
    availability_zone = "us-east-1a"
     tags = {
        Name = "first-zone"
    }
}

resource "aws_subnet" "subnet2"{
    vpc_id = aws_vpc.vpc1.id
    cidr_block = "10.0.0.32/28"
    availability_zone = "us-east-1b"

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
    ami = "ami-09e67e426f25ce0d7"
    instance_type = "t2.micro"
    availability_zone = "us-east-1a"
    key_name = "primary-key"

    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.network-1.id
    }

    user_data = <<-EOF
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo first instance works > /var/www/html/index.html'
                EOF
    tags = {
        Name = "web-server"
    }

}

resource "aws_instance" "web-server-instance2"{
    ami = "ami-09e67e426f25ce0d7"
    instance_type = "t2.micro"
    availability_zone = "us-east-1b"
    key_name = "primary-key"


    network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.network-2.id
    }

    user_data = <<-EOF
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo second instance works > /var/www/html/index.html'
                EOF
    tags = {
        Name = "web-server2"
    }

}

/*resource "aws_alb" "load balancer"{
  name = "test-1"
  load_balancer_type = "application"
  subnets = [aws.subnet1.id, ]

  security_groups = [aws_security_group.allow_security.id]


  resource "aws_lb_target_group" "target_group"{
    name = "target-group"
    port = 80
    protocol = "HTTP"
    target_type = "ip"
    vpc_id = "aws"
    }
  
  resource "aws_lb_listener" "listener"{
    load_balancer_arn = aws_alb.application_load_balancer.arn
    port = 80
    protocol = "HTTP"
    default action {
      type = "forward"
      target_group_arn =  aws_lb_target_group.target_group.arn
    }
  }

  "aws_ecs service"{
    load balancer{
      target_group_arn = aws_lb_target_group.arn
      container_name = aws_ecs_task_definition.my_first_task.family
      container_port = 3300
    }
  }
}


*/