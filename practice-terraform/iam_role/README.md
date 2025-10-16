# IAM ロールの作成

- `name`:
  - IAM ロールと IAM ポリシーの名前
- `policy`:
  - IAM ポリシーの内容
- `identifier`:
  - IAM ロールを関連付ける AWS リソースの識別子

# 使用例

```hcl
module "describe_regions_for_ec2" {
  source = "./iam_role"
  name = "describe-regions-for-ec2"
  policy = data.aws_iam_policy_document.allow_describe_regions.json
  identifier = "ec2.amazonaws.com"
}
```
