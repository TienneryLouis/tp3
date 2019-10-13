provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
  access_key = "AKIA6N4RZV6SM3CMCOHP"
  secret_key = "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"
}

resource "aws_instance" "webLouis" {
	vpc_security_group_ids = [
		"${aws_security_group.allow_ssh.id}"]
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.lti_sn.id}"
  key_name = "${aws_key_pair.key_tiennery.key_name}"
  tags = {
    Name = "TerraLouis"
  }

  provisioner "remote-exec" {
	inline = [
	"sudo apt-get update -y",
	"sudo apt install openjdk-11-jdk -y",
	"sudo pat install openjdk-11-jre -y",
	"sudo apt-get remove maven2 -y",
	"sudo apt-get install maven -y",
	"sudo apt-get install git -y",
	"git clone https://github.com/spring-projects/spring-petclinic.git",
	"sudo ufw allow 8080",
	"cd spring-petclinic",
	"./mvnw package"
	#"java -jar target/*.jar",
	]

	connection {
		type = "ssh"
		host = "${self.public_ip}"
		user = "ubuntu"
		private_key = "${file("privatekey")}"
	}
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-14.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_vpc" "lti_vpc" {
	cidr_block = "172.16.0.0/16"
	enable_dns_hostnames = true
	enable_dns_support = true

	tags = {
		Name = "lti_vpc"
	}
}

resource "aws_subnet" "lti_sn" {
	cidr_block = "${cidrsubnet(aws_vpc.lti_vpc.cidr_block, 3, 1)}"
	vpc_id = "${aws_vpc.lti_vpc.id}"
	availability_zone = "us-east-1f"
	map_public_ip_on_launch = true

	tags = {
		Name = "lti_sn"
	}
	

}

resource "aws_internet_gateway" "lti_igw" {
	vpc_id = "${aws_vpc.lti_vpc.id}"
}


resource "aws_route_table" "lti_rt" {
	vpc_id = "${aws_vpc.lti_vpc.id}"

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.lti_igw.id}"
	}

	tags = {
		Name = "lti_rt"
	}
}

resource "aws_route_table_association" "lti_rta" {
	subnet_id = "${aws_subnet.lti_sn.id}"
	route_table_id = "${aws_route_table.lti_rt.id}"
}

resource "aws_security_group" "allow_ssh" {
	name = "allow_ssh"
	vpc_id = "${aws_vpc.lti_vpc.id}"

	ingress {
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
}

resource "aws_key_pair" "key_tiennery" {
	key_name = "puKe"
	public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAjLyr7dppuptZi5UZk2a2H2EhXKpeR9i9Lsx64SwBYewn9zeUipFvKiC4IztiSdpJOLT2rYeix/FDvcrcmmbXGh6dEJbQtFYsAUGOPnrc2CnS1BHYIkAqTb4y30FBIJPDB4N1q3heep5U0P1Ed6c5cYpVDp+qNjQvGV2O3x3ZAxMjgUK0YZopjolSG+PVe8e+fVa2n3UztUQuOqzo7J0GPbecvUaheXANQkza97mEbUccPqiXZjrPyzkyc7s3gE9TNjtKV3hjF1ROmNSNh0xIiGU8LYe/rofkLvp062NnB1GThbQ1Q0ZZI+QWLWe9eFQeJybMzkLfB0//2C1kniAjqw== rsa-key-20191008"
}