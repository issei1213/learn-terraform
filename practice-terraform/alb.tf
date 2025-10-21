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
  enable_deletion_protection = false // 削除保護を有効化

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

# HTTPSリスナーの定義
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.example.arn
  port              = "443"                           // HTTPSポート
  protocol          = "HTTPS"                         // プロトコル
  certificate_arn   = aws_acm_certificate.example.arn // 作成したSSL証明書を参照
  ssl_policy        = "ELBSecurityPolicy-2016-08"     // SSLポリシー

  // デフォルトアクション：固定レスポンス
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "これは「HTTPS」です"
      status_code  = 200
    }
  }
}

# HTTPSリスナーの定義
resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_lb.example.arn
  port              = "8080" // HTTPポート
  protocol          = "HTTP" // プロトコル

  // デフォルトアクション：リダイレクト
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

}

resource "aws_lb_listener_rule" "example" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 100 // リスナールールの優先度 

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

// ECSと紐づけるためのターゲットグループの定義
resource "aws_lb_target_group" "example" {
  name                 = "example"
  target_type          = "ip"               // ECSの場合は"ip"
  vpc_id               = aws_vpc.example.id // target_typeが"ip"の場合はVPC IDが必須
  port                 = 80                 // target_typeが"ip"の場合はポートが必須
  protocol             = "HTTP"             // target_typeが"ip"の場合はプロトコルが必須。ALBの終端がHTTPであるため。
  deregistration_delay = 300                // ターゲット登録解除の遅延時間（秒）

  health_check {
    path                = "/"            // ヘルスチェックのパス
    healthy_threshold   = 5              // ヘルシー判定の閾値
    unhealthy_threshold = 2              // アンヘルシー判定の閾値
    timeout             = 5              // ヘルスチェックのタイムアウト時間（秒）
    interval            = 200            // ヘルスチェックの間隔時間（秒）
    port                = "traffic-port" // ヘルスチェックのポート
    protocol            = "HTTP"         // ヘルスチェックのプロトコル
  }

  depends_on = [aws_lb.example]
}

output "alb_dns_name" {
  value = aws_lb.example.dns_name
}
