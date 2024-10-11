variable "cidr" {
    default = "10.0.0.0/16" 
}

resource "aws_key_pair" "example" {
    key_name = "terraform-demo"
    public_key = file("C:/Users/sadab/Downloads/sadabtf/id_rsa.pub") 
}

resource "aws_vpc" "myvpc" {
    cidr_block = var.cidr 
}

resource "aws_subnet" "sub1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.myvpc.id
}

resource "aws_route_table" "rta1" {
    vpc_id = aws_vpc.myvpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

}

resource "aws_route_table_association" "rta2" {
    subnet_id = aws_subnet.sub1.id
    route_table_id = aws_route_table.rta1.id
  
}

resource "aws_security_group" "websg" {
    name = "web"
    vpc_id = aws_vpc.myvpc.id

    ingress  {
     description = "allow port for HTTP "
     from_port = 80
     to_port = 80
     protocol = "tcp"
     cidr_blocks = [ "0.0.0.0/0" ]

    }

   ingress {
     description = "allow port for HTTP "
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]

    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "websg"
    }
  
}

resource "aws_instance" "server" {
    ami = "ami-0866a3c8686eaeeba"
    instance_type = "t2.micro"
    key_name = aws_key_pair.example.key_name
    vpc_security_group_ids = [ aws_security_group.websg.id]
    subnet_id = aws_subnet.sub1.id

    connection {
      type = "ssh"
      user = "ubuntu"
     private_key = file("C:/Users/sadab/Downloads/sadabtf/id_rsa")
      host = self.public_ip
    }

    provisioner "file" {
        source = "index.html"
        destination = "/home/ubuntu/index.html"

      
    }
    
    provisioner "remote-exec" {
        inline = [ 
         "sudo apt update -y",
         "sudo apt install nginx -y",
         "cp /home/ubuntu/index.html /var/www/html/index.html "
        ]

      
    }

    
}