# DBインスタンスのセキュリティグループの定義
module "mysql_sg" {
  source      = "./security_group"
  name        = "mysql_sg"
  vpc_id      = aws_vpc.example.id
  port        = 3306
  cidr_blocks = [aws_vpc.example.cidr_block]
}

# DBパラメータグループの定義
resource "aws_db_parameter_group" "example" {
  name   = "name"
  family = "mysql8.0"

  parameter { // DBの設定パラメータを設定していく
    name  = "character_set_database"
    value = "utf8mb4"
  }

  parameter {
    name  = "character_set_server"
    value = "utf8mb4"
  }
}

# DBオプショングループの定義
# データベースエンジンにオプション機能を追加する
resource "aws_db_option_group" "example" {
  name                 = "example"
  engine_name          = "mysql"
  major_engine_version = "8.0"

  option {
    option_name = "MARIADB_AUDIT_PLUGIN" // 監査ログを有効化するオプション
  }
}

# DBサブネットグループの定義
resource "aws_db_subnet_group" "example" {
  name = "example"
  subnet_ids = [
    aws_subnet.private_0.id,
    aws_subnet.private_1.id,
  ]
}

# DBインスタンスの定義
resource "aws_db_instance" "example" {
  identifier                 = "example" // 識別子
  engine                     = "mysql"
  engine_version             = "8.0.42"
  instance_class             = "db.t3.micro"
  allocated_storage          = 20    // ストレージ容量（GB）
  max_allocated_storage      = 100   // ストレージ自動拡張の上限（GB）
  storage_type               = "gp2" // 汎用SSD
  storage_encrypted          = true
  kms_key_id                 = aws_kms_key.example.arn // KMSキーでストレージを暗号化
  username                   = "admin"
  password                   = "VeryStringPassword!"
  multi_az                   = true
  publicly_accessible        = false // パブリックアクセス不可
  backup_window              = "09:10-09:40"
  maintenance_window         = "mon:10:10-mon:10:40"
  auto_minor_version_upgrade = false
  deletion_protection        = false // 本来であれば true にするべきだが、学習のため今回は false に設定
  skip_final_snapshot        = true  // 本来であれば false にするべきだが、学習のため今回は true に設定
  port                       = 3306
  apply_immediately          = false // 変更時にダウンタイムが発生するため、即時適用しない
  vpc_security_group_ids = [
    module.mysql_sg.security_group_id
  ]
  parameter_group_name = aws_db_parameter_group.example.name
  option_group_name    = aws_db_option_group.example.name
  db_subnet_group_name = aws_db_subnet_group.example.name

  lifecycle {
    ignore_changes = [password]
  }
}
