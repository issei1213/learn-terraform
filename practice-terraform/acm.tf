# SSL証明書の定義
resource "aws_acm_certificate" "example" {
  domain_name               = aws_route53_record.example.name // 作成したDNSレコードを参照
  subject_alternative_names = []                              // 必要に応じて追加のSLを指定
  validation_method         = "DNS"                           // DNS検証を使用

  lifecycle {
    create_before_destroy = true // デフォルトではリソース削除→作成の順で行われるが、先に作成してから削除するように設定
  }

  tags = {
    Name = "example-cert"
  }
}

# SSL証明書の検証用のレコードの定義
resource "aws_route53_record" "example_certificate" {
  for_each = {
    for dvo in aws_acm_certificate.example.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.test_example.zone_id
}

# SSL証明書の検証完了までの待機
resource "aws_acm_certificate_validation" "example" {
  certificate_arn         = aws_acm_certificate.example.arn
  validation_record_fqdns = [for record in aws_route53_record.example_certificate : record.fqdn]
}
