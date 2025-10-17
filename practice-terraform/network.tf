# VPCの定義
resource "aws_vpc" "example" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true // Route53のDNSサポートを有効化
  enable_dns_hostnames = true // VPC内のインスタンスにホスト名を自動割り当て

  tags = {
    Name = "example-vpc"
  }
}


# --------------------------------
# パブリックサブネット
# --------------------------------
# パブリックサブネットのマルチAZ化
resource "aws_subnet" "public_0" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true // インスタンス起動時にパブリックIPを自動割り当て
  availability_zone       = "ap-northeast-1a"

  tags = {
    Name = "example-public-subnet-0"
  }
}

resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true // インスタンス起動時にパブリックIPを自動割り当て
  availability_zone       = "ap-northeast-1c"

  tags = {
    Name = "example-public-subnet-1"
  }
}

# インターネットゲートウェイの定義
resource "aws_internet_gateway" "example" {
  vpc_id = aws_vpc.example.id

  tags = {
    Name = "example-igw"
  }
}

# ルートテーブルの定義
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "example-public-rt"
  }
}

# ルートテーブルにデフォルトルートを追加。VPC外への通信をインターネットゲートウェイ経由に設定
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  gateway_id             = aws_internet_gateway.example.id
  destination_cidr_block = "0.0.0.0/0"
}

# サブネットとルートテーブルを関連付けをマルチAZ化
resource "aws_route_table_association" "public_0" {
  subnet_id      = aws_subnet.public_0.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

# --------------------------------
# プライベートサブネット
# --------------------------------
# プライベートサブネットのマルチAZ化
resource "aws_subnet" "private_0" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.65.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false // インスタンス起動時にパブリックIPを割り当てない

  tags = {
    Name = "example-private-subnet-0"
  }
}

resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.example.id
  cidr_block              = "10.0.66.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = false // インスタンス起動時にパブリックIPを割り当てない

  tags = {
    Name = "example-private-subnet-1"
  }
}

# プライベートルートテーブルと関連付けの定義
# プライベートサブネットのルートテーブルのマルチAZ化
resource "aws_route_table" "private_0" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "example-private-rt-0"
  }
}

resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.example.id
  tags = {
    Name = "example-private-rt-1"
  }
}

resource "aws_route_table_association" "private_0" {
  subnet_id      = aws_subnet.private_0.id
  route_table_id = aws_route_table.private_0.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

# NATゲートウェイのマルチAZ化
resource "aws_eip" "nat_gateway_0" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.example]

  tags = {
    Name = "example-nat-eip"
  }
}

resource "aws_eip" "nat_gateway_1" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.example]

  tags = {
    Name = "example-nat-eip"
  }
}

# NATゲートウェイの定義。パブリックサブネットからのインターネットアクセスを提供
resource "aws_nat_gateway" "nat_gateway_0" {
  allocation_id = aws_eip.nat_gateway_0.id
  subnet_id     = aws_subnet.public_0.id
  depends_on    = [aws_internet_gateway.example]

  tags = {
    Name = "example-nat-gateway-0"
  }
}

resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1.id
  subnet_id     = aws_subnet.public_1.id
  depends_on    = [aws_internet_gateway.example]

  tags = {
    Name = "example-nat-gateway-1"
  }
}

# プライベートネットワークからインターネットへ通信するためのルート設定
# プライベートルートテーブルにデフォルトルートを追加。VPC外への通信をNATゲートウェイ経由に設定
resource "aws_route" "private_0" {
  route_table_id         = aws_route_table.private_0.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_0.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route" "private_1" {
  route_table_id         = aws_route_table.private_1.id
  nat_gateway_id         = aws_nat_gateway.nat_gateway_1.id
  destination_cidr_block = "0.0.0.0/0"
}

# セキュリティグループの定義
resource "aws_security_group" "example" {
  name   = "example-sg"
  vpc_id = aws_vpc.example.id
}

# セキュリティグループルール（インバウンド）の定義
resource "aws_security_group_rule" "ingress_example" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.example.id
}

# セキュリティグループルール（アウトバウンド）の定義
resource "aws_security_group_rule" "egress_example" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.example.id
}
