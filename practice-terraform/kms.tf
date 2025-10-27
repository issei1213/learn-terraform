# カスタマーマスターキーの定義
resource "aws_kms_key" "example" {
  description             = "Example Customer Master Key" // 何の用途で使っているかを記述
  enable_key_rotation     = true                          // 自動ローテーション
  is_enabled              = true                          // カスタマーマスターキーを有効化
  deletion_window_in_days = 30                            // カスタマーマスターキーの削除は推奨されない
}

# エイリアスの定義
# UUIDが自動で割り振られるので、代わりにわかりやすい名前をつける
resource "aws_kms_alias" "example" {
  name          = "alias/example"
  target_key_id = aws_kms_key.example.key_id
}

