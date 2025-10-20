# アプリケーションロードバランサーのセキュリティグループの定義
module "http_sg" {
  source      = "./security_group"
  name        = "http-sg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = ["0.0.0.0/0"]
}

module "https_sg" {
  source      = "./security_group"
  name        = "https-sg"
  vpc_id      = aws_vpc.example.id
  port        = 443
  cidr_blocks = ["0.0.0.0/0"]
}

module "http_redirect_sg" {
  source      = "./security_group"
  name        = "http-redirect-sg"
  vpc_id      = aws_vpc.example.id
  port        = 8080
  cidr_blocks = ["0.0.0.0/0"]
}

# アプリケーションロードバランサーの定義
resource "aws_lb" "example" {
  name                       = "example"
  load_balancer_type         = "application"
  internal                   = false // インターネット向け
  idle_timeout               = 60    // タイムアウト時間（秒）
  enable_deletion_protection = true  // 削除保護を有効化

  // パブリックサブネットに配置
  subnets = [
    aws_subnet.public_0.id,
    aws_subnet.public_1.id
  ]

  // アクセスログの設定
  access_logs {
    bucket  = aws_s3_bucket.alb_log.id
    enabled = true
  }

  security_groups = [
    module.http_sg.security_group_id,
    module.https_sg.security_group_id,
    module.http_redirect_sg.security_group_id
  ]
}

# HTTPリスナーの定義
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port              = "80"   // HTTPポート
  protocol          = "HTTP" // プロトコル

  // デフォルトアクション：固定レスポンス
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは「HTTP」です"
      status_code  = 200
    }
  }
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
}
