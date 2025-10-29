# ElasticCache レプリケーショングループのセキュリティグループの定義
module "redis_sg" {
  source      = "./security_group"
  name        = "redis_sg"
  vpc_id      = aws_vpc.example.id
  port        = 6379
  cidr_blocks = [aws_vpc.example.cidr_block]
}

# ElasticCacheパラメータグループの定義
resource "aws_elasticache_parameter_group" "example" {
  name   = "example"
  family = "redis6.x"

  parameter {
    name  = "cluster-enabled"
    value = "no" // コストを考慮してクラスター無効化
  }
}

# ElasticCacheのサブネットグループの定義
resource "aws_elasticache_subnet_group" "example" {
  name       = "example-subnet-group"
  subnet_ids = [aws_subnet.private_0.id, aws_subnet.private_1.id]

  tags = {
    Name = "example-subnet-group"
  }
}

# ElasticCacheレプリケーショングループの定義
resource "aws_elasticache_replication_group" "example" {
  replication_group_id       = "example"
  description                = "Cluster Disabled"
  engine                     = "redis"
  engine_version             = "6.x"
  num_cache_clusters         = 3 // ノード数を3に設定。プライマリーノード1台、レプリカノード2台
  node_type                  = "cache.t3.micro"
  snapshot_window            = "09:10-10:10" // スナップショット取得ウィンドウ
  snapshot_retention_limit   = 7
  maintenance_window         = "mon:10:40-mon:11:40" // メンテナンスウィンドウ
  automatic_failover_enabled = true
  port                       = 6379
  apply_immediately          = false
  security_group_ids = [
    module.redis_sg.security_group_id
  ]
  parameter_group_name = aws_elasticache_parameter_group.example.name
  subnet_group_name    = aws_elasticache_subnet_group.example.name

  tags = {
    Name = "example-replication-group"
  }
}
