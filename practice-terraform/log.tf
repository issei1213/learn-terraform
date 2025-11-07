# --------------------------------
# Cloud Watch Logs 
# --------------------------------
# Cloud Watch log 永続化バケットの定義
resource "aws_s3_bucket" "cloudwatch_log" {
  bucket = "cloudwatch-logs-pragmatic-terraform"
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudwatch_log_lifecycle" {
  bucket = aws_s3_bucket.cloudwatch_log.id

  rule {
    id     = "log-lifecycle-rule"
    status = "Enabled"

    expiration {
      days = 180
    }
  }
}

# Kinesis Data FirehoseのIAMロールのポリシードキュメントの定義
data "aws_iam_policy_document" "kinesis_firehose_role_filehose" {
  statement {
    effect = "Allow"

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${aws_s3_bucket.cloudwatch_logs.id}",
      "arn:aws:s3:::${aws_s3_bucket.cloudwatch_logs.id}/*"
    ]
  }
}

# Kinesis Data FirehoseのIAMロールの定義
module "kinesis_data_firehose_role" {
  source     = "../iam-role"
  name       = "kinesis-data-firehose"
  identifier = "kinesis.amazonaws.com"
  policy     = data.aws_ism_policy_document.kinesis_data_firehose.json
}

# Kinesis Data Firehose 配信ストリームの定義
resource "aws_kinesis_firehose_delivery_stream" "example" {
  name        = "example"
  destination = "s3"

  extended_s3_configuration {
    role_arn   = module.kinesis_data_firehose_role.iam_role_arn
    bucket_arn = aws_s3_bucket.cloudwatch_log.arn
    prefix     = "ecs-scheduled-tasks/example/"
  }
}

# Cloud Watch Logs IAMロールポリシードキュメントの定義
data "aws_iam_policy_document" "cloudwatch_logs" {
  statement {
    effect    = "Allow"
    actions   = ["firehose:*"]
    resources = ["arn:aws:firehose:ap-northeast-1:*:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = ["arn:aws:iam::*:role/cloudwatch-logs"]
  }
}


# Cloud Watch Logs のIAMロールの定義
module "cloudwatch_logs_role" {
  source     = "../iam-role"
  name       = "cloudwatch-logs"
  identifier = "logs.ap-northeast-1.amazonaws.com"
  policy     = data.aws_iam_policy_document.cloudwatch_logs.json
}

# Cloud Watch Logs サブスクリプションフィルタの定義
resource "aws_cloudwatch_log_subscription_filter" "example" {
  name            = "example"
  log_group_name  = "ecs_cloudwatch_log_group.for_ecs_scheduled_tasks.name" // ECSタスクで作成したCloud Watch Logsのロググループ名を指定
  destination_arn = aws_kinesis_firehose_delivery_stream.example.arn
  filter_pattern  = "[]"
  role_arn        = module.cloudwatch_logs_role.iam_role_arn
}
