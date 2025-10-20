resource "random_string" "s3_unique_key" {
  length  = 6
  upper   = false
  lower   = true
  numeric = true
  special = false
}

# --------------------------------
# プライベートバケット
# --------------------------------
# プライベートバケットの定義
resource "aws_s3_bucket" "private" {
  bucket = "private-pragmatic-terraform-${random_string.s3_unique_key.result}"
}

# バージョニングでいつでも旧バージョンに戻せるようにする
resource "aws_s3_bucket_versioning" "s3_bucket_private_versioning" {
  bucket = aws_s3_bucket.private.id

  versioning_configuration {
    status = "Enabled"
  }
}

# オブジェクトを保存時に暗号化する設定。復元時には自動で復元される。
resource "aws_s3_bucket_server_side_encryption_configuration" "aws_s3_bucket_private_server_side_encryption_configuration" {
  bucket = aws_s3_bucket.private.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# ブロックパブリックアクセスの定義
resource "aws_s3_bucket_public_access_block" "private" {
  bucket = aws_s3_bucket.private.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --------------------------------
# パブリックバケット
# --------------------------------
# パブリックバケットの定義
resource "aws_s3_bucket" "public" {
  bucket = "public-pragmatic-terraform-${random_string.s3_unique_key.result}"
}

# バケットの Object Ownership を ACL が使える設定に変更
resource "aws_s3_bucket_ownership_controls" "public" {
  bucket = aws_s3_bucket.public.id

  rule {
    # ACL を許可したい場合、BucketOwnerPreferred または ObjectWriter を指定します
    # - "BucketOwnerPreferred": バケット所有者が優先されるが ACL は許可される
    # - "ObjectWriter": オブジェクト作成者が所有者となる（ACL 利用可）
    object_ownership = "BucketOwnerEnforced"
  }
}

# バケットの公開をポリシーで許す（ACLは使わない）
resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.public.id

  # ポリシーでの公開をブロックしない
  block_public_policy     = false
  restrict_public_buckets = false

  # ACL は使わないのでブロックしてOK
  block_public_acls  = true
  ignore_public_acls = true
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.public.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Sid       = "PublicReadGetObject"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = ["${aws_s3_bucket.public.arn}/*"]
      }
    ]
  })

  # パブリックアクセスブロックの設定後にポリシーを適用
  depends_on = [aws_s3_bucket_public_access_block.public]
}


# CORS設定。特定のオリジンからのGETリクエストを許可する。
resource "aws_s3_bucket_cors_configuration" "s3_bucket_public_cors_configuration" {
  bucket = aws_s3_bucket.public.id

  cors_rule {
    allowed_origins = ["https://example.com"]
    allowed_methods = ["GET"]
    allowed_headers = ["*"]
    max_age_seconds = 3000
  }
}

# --------------------------------
# ALBログバケット
# --------------------------------
# ログバケットの定義
resource "aws_s3_bucket" "alb_log" {
  bucket = "alb-log-pragmatic-terraform-${random_string.s3_unique_key.result}"
}

# ALBのアクセスログ保存用に180日後にオブジェクトを削除するライフサイクルルールの設定
resource "aws_s3_bucket_lifecycle_configuration" "aws_s3_bucket_alb_log_lifecycle_configuration" {
  bucket = aws_s3_bucket.alb_log.id

  rule {
    id     = "log-expiration-rule"
    status = "Enabled"
    expiration {
      days = "180"
    }
  }
}

# バケットポリシーでALBからの書き込みを許可する
resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.alb_log.id
  policy = data.aws_iam_policy_document.alb_log_policy.json
}

data "aws_iam_policy_document" "alb_log_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["582318560864"] # ap-northeast-1のELBサービスアカウント
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}/*"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.alb_log.id}"]

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
  }
}
