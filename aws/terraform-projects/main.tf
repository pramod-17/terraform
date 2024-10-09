resource "aws_vpc" "myvpc" {
  cidr_block       = var.cidr
  instance_tenancy = "default"

  tags = {
    Name = "test"
  }
}

resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.sub1
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "pubsub"
  }

}

resource "aws_subnet" "sub2" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = var.sub2
  availability_zone = "us-east-1b"

  tags = {
    Name = "pvtsub"
  }

}

resource "aws_eip" "nat_eip" {

  tags = {
    Name = "nateip"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "myigw"
  }

}

resource "aws_nat_gateway" "mynat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.sub1.id

  tags = {
    Name = "mynatgw"
  }
}

resource "aws_route_table" "pubRT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id

  }

  tags = {
    Name = "pubRT"
  }
}

resource "aws_route_table_association" "mypubrta" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.pubRT.id

}

resource "aws_route_table" "pvtRT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.mynat.id


  }

  tags = {
    Name = "pvtRT"
  }
}

resource "aws_route_table_association" "mypvtrta" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.pvtRT.id

}





resource "aws_security_group" "websg" {
  name        = "websg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    description = "http from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ssh from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "https from VPC"
    from_port   = 443
    to_port     = 443
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
    Name = "web-sg"
  }
}


resource "aws_instance" "webserver1" {
  ami                    = var.amiid
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.sub1.id
  key_name               = "him"
  vpc_security_group_ids = [aws_security_group.websg.id]
  user_data              = base64encode(file("userdata.sh"))

  tags = {
    Name = "pubserver"
  }


}

resource "null_resource" "copy_file_to_webserver1" {
  provisioner "file" {
    source      = "./him.pem"
    destination = "/home/ubuntu/him.pem"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("him.pem")
      host        = aws_instance.webserver1.public_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 400 /home/ubuntu/him.pem",
      "echo 'File copied successfully to Instance 1!'"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("him.pem")
      host        = aws_instance.webserver1.public_ip
    }
  }
}

resource "aws_instance" "webserver2" {
  ami                    = var.amiid
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.sub2.id
  key_name               = "him"
  vpc_security_group_ids = [aws_security_group.websg.id]
  user_data              = base64encode(file("userdata1.sh"))

  tags = {
    Name = "pvtserver"
  }


}

#createing alb (application LoadBalancer)

resource "aws_lb" "mylb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.websg.id]

  subnets = [aws_subnet.sub1.id, aws_subnet.sub2.id]

  tags = {
    Name = "web"
  }

}

resource "aws_lb_target_group" "tg" {
  name     = "mytg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"
  }

}

resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.webserver2.id
  port             = 80
}

resource "aws_lb_listener" "listner" {
  load_balancer_arn = aws_lb.mylb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.tg.arn
    type             = "forward"
  }

}


