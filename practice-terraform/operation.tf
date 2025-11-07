# オペレーションサーバー用のポリシードキュメントの定義
# EC2は直接IAMロールをアタッチできないため、インスタンスプロファイルを作成する
data "aws_iam_policy_document" "ec2_for_ssm" {
  json = data.aws_iam_policy.ec2_for_ssm.aws_iam_policy

  statement {
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "s3:PutObject", // S3へのログ保存などに必要
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ssm:GetParameter",
      "ssm:GetParameters",
      "ssm:GetParameterByPath",
      "kms:Decrypt"
    ]
  }
}

data "aws_iam_policy" "ec2_for_ssm" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# オペレーションサーバー用IAMロールの定義
module "ec2_for_ssm_role" {
  source     = "./iam_role"
  name       = "ec2-for-ssm"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy.ec2_for_ssm.json
}

# インスタンスプロファイルの定義
resource "aws_iam_instance_profile" "ec2_for_ssm" {
  name = "ec2-for-ssm"
  role = module.ec2_for_ssm_role.iam_role_name
}

# オペレーションサーバー用EC2インスタンスの定義
resource "aws_instance" "example_for_operation" {
  ami                  = "ami-070e0d4707168fc07"
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_for_ssm.name
  subnet_id            = aws_subnet.private_0.id
  user_data            = file("./user_data.sh") // オペレーションサーバー用User Dataの定義

}

output "operation_instance_id" {
  value = aws_instance.example_for_operation.id
}

#----------------------------
# オペレーションサーバーログ
#---------------------------- 
# オペレーションログを保存するS3バケットの定義
resource "aws_s3_bucket" "operation" {
  bucket = "operation-pragmatic-terraform"

}

resource "aws_s3_bucket_lifecycle_configuration" "operation_log_lifecycle" {
  bucket = aws_s3_bucket.operation.id

  rule {
    id     = "log-expiration-rule"
    status = "Enabled"
    expiration {
      days = "180"
    }
  }
}

#----------------------------
# CloudWatch Logs
#---------------------------- 
# オペレーションログを保存するCloudWatch Logsの定義
resource "aws_cloudwatch_log_group" "operation" {
  name              = "./operation"
  retention_in_days = 180
}




# --------------------------------
# SSM Document
# --------------------------------
resource "aws_ssm_document" "session_manager_run_shell" {
  name            = "SSM-SessionManagerRunShell"
  document_type   = "Session"
  document_format = "JSON"

  content = <<EOF
    {
        "schemaVersion": "2.0",
        "description": "Document to hold regional settings for session Manager",
        "sessionType": "Standard_Stream",
        "inputs": {
            "s3BucketName": "${aws_s3_bucket.operation.id}",
            "cloudWatchLogGroupName": "${aws_cloudwatch_log_group.operation.name}"
        }
    }
    EOF
}
