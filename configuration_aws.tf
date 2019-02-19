

#VARIABLES


#variable "access_key" {}
#variable "secret_key" {}
variable "SUBNET" {}
#PROVIDER AMAZON

provider "aws" {
  access_key = "AKIAIO2V7ANK4X4SIAMA"
  secret_key = "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"
  region     = "eu-west-3"
  
}


#provider "aws" {
#  access_key = "${var.access_key}"
#  secret_key = "${var.secret_key}"
 # region     = "eu-west-1"
  
#}


#VPC


resource "aws_vpc" "Paris" {
  cidr_block       = "10.11.0.0/16"
  instance_tenancy = "dedicated"
	assign_generated_ipv6_cidr_block = true
	enable_dns_hostnames =true 
 tags {
    Name = "Paris"
  }
}

#SUBNETS

resource "aws_subnet" "vpp" {
  vpc_id     = "${aws_vpc.Paris.id}"
  cidr_block = "10.11.1.0/24"
	availability_zone = "eu-west-3a"
  tags {
    Name = "vpp"
  }
}

resource "aws_subnet" "management" {
  vpc_id     = "${aws_vpc.Paris.id}"
  cidr_block = "10.11.2.0/24"
	availability_zone = "eu-west-3a"
  tags {
    Name = "management"
  }
}


resource "aws_subnet" "ipv6" {
  vpc_id     = "${aws_vpc.Paris.id}"
  cidr_block = "10.11.3.0/24"
  ipv6_cidr_block = "${cidrsubnet(aws_vpc.Paris.ipv6_cidr_block, 8, 1)}"
  availability_zone = "eu-west-3a"
    assign_ipv6_address_on_creation = true
    tags {
    Name = "ipv6"
  }
}

#INTERNET GATEWAY

resource "aws_internet_gateway" "vpc_igw" {
    vpc_id = "${aws_vpc.Paris.id}"

  tags {
    Name = "main"
  }
}

#ROUTE TABLES


resource "aws_default_route_table" "rt" {
    
    default_route_table_id = "${aws_vpc.Paris.default_route_table_id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.vpc_igw.id}"
    }

    route {
        ipv6_cidr_block = "::/0"
        gateway_id = "${aws_internet_gateway.vpc_igw.id}"
    }
}

#resource "aws_route_table_association" "association1" {
   
 #   subnet_id      = "${aws_subnet.vpp.id}"
 #   route_table_id = "${aws_default_route_table.rt.id}"
#}

resource "aws_route_table_association" "association2" {
   
    subnet_id      = "${aws_subnet.management.id}"
    route_table_id = "${aws_default_route_table.rt.id}"
}

resource "aws_route_table_association" "association3" {
   
    subnet_id      = "${aws_subnet.ipv6.id}"
    route_table_id = "${aws_default_route_table.rt.id}"
}

resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.Paris.id}"

  route {
    cidr_block = "${var.SUBNET}"
    network_interface_id = "${aws_network_interface.vppIPV4.id}"
  }

route {
        cidr_block = "0.0.0.0/0"
	#ipv6_cidr_block = "::/0"
        gateway_id = "${aws_internet_gateway.vpc_igw.id}"
    }

  tags {
    Name = "Paris"
  }
}

resource "aws_route_table_association" "association" {
  subnet_id      = "${aws_subnet.vpp.id}"
  route_table_id = "${aws_route_table.r.id}"
}



#SECURITY GROUP

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.Paris.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }

 egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks  = ["::/0"]
  }


 tags {
    Name = "allow_all"
  }
 
}


#INSTANCE WITH VPP CREATED BY ME


resource "aws_instance" "VPP-Paris" {
  ami           = "ami-28fd4c55"
  instance_type = "m5.large"
  key_name = "VPP_Paris"
  vpc_security_group_ids= ["${aws_security_group.allow_all.id}"]
#security_groups = ["${aws_security_group.allow_all.id}"]	
	subnet_id="${aws_subnet.management.id}"
	availability_zone = "eu-west-3a"
#user_data       = "${data.template_file.user-data.rendered}"
tags {
    Name = "VPP-Paris"
  }

}

#data template_file "user-data"
#{
#    template = "${file("script_interfaces.sh")}"
#}


#ASSIGN KEYPAIR


#NETWORK INTERFACES

resource "aws_network_interface" "vppIPV4" {
  subnet_id       = "${aws_subnet.vpp.id}"
  
  security_groups = ["${aws_security_group.allow_all.id}"]
  source_dest_check = false
  attachment {
    instance     = "${aws_instance.VPP-Paris.id}"
    device_index = 1
  }
}


resource "aws_network_interface" "vppIPV6" {
  subnet_id       = "${aws_subnet.ipv6.id}"
  
  security_groups = ["${aws_security_group.allow_all.id}"]
   source_dest_check = false
  attachment {
    instance     = "${aws_instance.VPP-Paris.id}"
    device_index = 2
  }
}



#ASSIGN EIP

resource "aws_eip" "ip" {
  instance = "${aws_instance.VPP-Paris.id}"
}



