# ホストゾーンのデータソース定義
locals {
  name = "issei1213.com"
}

# ホストゾーンのリソース定義
resource "aws_route53_zone" "test_example" {
  name          = "issei1213.com"
  force_destroy = false

  tags = {
    Name = "issei1213.com"
  }
}

# ALBのDNSレコードの定義
resource "aws_route53_record" "example" {
  zone_id = aws_route53_zone.test_example.zone_id
  name    = local.name
  type    = "A"

  alias {
    name                   = aws_lb.example.dns_name
    zone_id                = aws_lb.example.zone_id
    evaluate_target_health = true
  }
}

output "domain_name_http" {
  value = "http://${aws_route53_record.example.name}"
}

output "domain_name_https" {
  value = "https://${aws_route53_record.example.name}"
}
