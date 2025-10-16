variable "name" {}
variable "policy" {}
variable "identifier" {}

# 信頼ポリシーの定義(どのAWSリソースにどのロールを関連づけるか)
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.identifier] // 特定のAWSリソースにロールを関連づける
    }
  }
}

# IAMポリシーの定義
resource "aws_iam_role" "default" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# IAMポリシーの定義
resource "aws_iam_policy" "default" {
  name   = var.name
  policy = var.policy
}

# IAMロールにIAMポリシーをアタッチ
resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}

# 出力
output "iam_role_arn" {
  value = aws_iam_role.default.arn
}

output "iam_role_name" {
  value = aws_iam_role.default.name
}
