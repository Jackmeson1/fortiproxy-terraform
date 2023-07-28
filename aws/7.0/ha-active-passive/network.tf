// Creating Internet Gateway
resource "aws_internet_gateway" "fpxvmigw" {
  vpc_id = aws_vpc.fpxvm-vpc.id
  tags = {
    Name = "fpxvm-igw"
  }
}

// Route Table
resource "aws_route_table" "fpxvmpublicrt" {
  vpc_id = aws_vpc.fpxvm-vpc.id

  tags = {
    Name = "fpxvm-public-rt"
  }
}

resource "aws_route_table" "fpxvmprivatert" {
  vpc_id = aws_vpc.fpxvm-vpc.id

  tags = {
    Name = "fpxvm-private-rt"
  }
}

resource "aws_route" "externalroute" {
  route_table_id         = aws_route_table.fpxvmpublicrt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.fpxvmigw.id
}

resource "aws_route" "internalroute" {
  depends_on             = [aws_instance.fpxactive]
  route_table_id         = aws_route_table.fpxvmprivatert.id
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.eth1.id

}

resource "aws_route_table_association" "public1associate" {
  subnet_id      = aws_subnet.publicsubnetaz1.id
  route_table_id = aws_route_table.fpxvmpublicrt.id
}

resource "aws_route_table_association" "public2associate" {
  subnet_id      = aws_subnet.publicsubnetaz2.id
  route_table_id = aws_route_table.fpxvmpublicrt.id
}

resource "aws_route_table_association" "hamgmt1associate" {
  subnet_id      = aws_subnet.hamgmtsubnetaz1.id
  route_table_id = aws_route_table.fpxvmpublicrt.id
}

resource "aws_route_table_association" "hamgmt2associate" {
  subnet_id      = aws_subnet.hamgmtsubnetaz2.id
  route_table_id = aws_route_table.fpxvmpublicrt.id
}

resource "aws_route_table_association" "internalassociate" {
  subnet_id      = aws_subnet.privatesubnetaz1.id
  route_table_id = aws_route_table.fpxvmprivatert.id
}

resource "aws_route_table_association" "internal2associate" {
  subnet_id      = aws_subnet.privatesubnetaz2.id
  route_table_id = aws_route_table.fpxvmprivatert.id
}

resource "aws_eip" "ClusterPublicIP" {
  depends_on        = [aws_instance.fpxactive]
  # vpc               = true
  domain            = "vpc"
  network_interface = aws_network_interface.eth0.id
}


resource "aws_eip" "MGMTPublicIP" {
  depends_on = [aws_instance.fpxactive]
  //depends_on        = [aws_network_interface.eth3]
  # vpc               = true
  domain            = "vpc"
  network_interface = aws_network_interface.eth3.id
}

resource "aws_eip" "PassiveMGMTPublicIP" {
  depends_on = [aws_instance.fpxpassive]
  //depends_on        = [aws_network_interface.passiveeth3]
  # vpc               = true
  domain            = "vpc"
  network_interface = aws_network_interface.passiveeth3.id
}


// Security Group

resource "aws_security_group" "public_allow" {
  name        = "Public Allow"
  description = "Public Allow traffic"
  vpc_id      = aws_vpc.fpxvm-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "6"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Public Allow"
  }
}

resource "aws_security_group" "allow_all" {
  name        = "Allow All"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.fpxvm-vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Public Allow"
  }
}
