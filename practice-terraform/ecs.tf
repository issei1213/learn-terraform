module "nginx_sg" {
  source      = "./security_group"
  name        = "nginx-sg"
  vpc_id      = aws_vpc.example.id
  port        = 80
  cidr_blocks = [aws_vpc.example.cidr_block]
}


# ECSタスク実行IAMロールの定義
module "ecs_task_execution_role" {
  source     = "./iam_role"
  name       = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.ecs_task_execution.json
}

# ECSクラスタの定義
resource "aws_ecs_cluster" "example" {
  name = "example-cluster"
}


# タスク定義
resource "aws_ecs_task_definition" "example" {
  family                   = "example" // タスク定義の名前。リビジョン番号は自動的に付与される
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions    = file("./container_definitions.json")        // コンテナ定義をJSONファイルから読み込む
  execution_role_arn       = module.ecs_task_execution_role.iam_role_arn // タスク実行IAMロールのARN
}

# ECSサービス
# 通常タスクは起動したら終了してしまう。これを防止するための、ECSサービスが必要
# 通常起動しておくタスクの数を指定したり、コンテナが落ちた時の自動で立ち上げてしれくれたりする
# ALBとECSサービスが紐づけて管理される
resource "aws_ecs_service" "example" {
  name                              = "example"
  cluster                           = aws_ecs_cluster.example.arn
  task_definition                   = aws_ecs_task_definition.example.arn
  desired_count                     = 2 // 1だとコンテナが落ちた時にサービスが復旧しない可能性があるため2にする
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = 60 // タスク起動後、ヘルスチェックを開始するまでの猶予期間（秒）

  network_configuration {    // ネットワーク構成
    assign_public_ip = false // プライベートサブネットに配置するためfalse
    security_groups  = [module.nginx_sg.security_group_id]

    subnets = [
      aws_subnet.private_0.id,
      aws_subnet.private_1.id
    ]
  }

  load_balancer { // タスク定義のどのコンテナのどのポートにALBのターゲットグループを紐づけるか
    target_group_arn = aws_lb_target_group.example.arn
    container_name   = "example" // コンテナ定義のname
    container_port   = 80        // コンテナ定義のportMappingsのcontainerPort
  }

  lifecycle {
    ignore_changes = [task_definition] // リソースの初回作成後、task_definitionの変更を無視する
  }
}

# CloudWatch Logsの定義
resource "aws_cloudwatch_log_group" "for_ecs" {
  name              = "/ecs/example"
  retention_in_days = 180 // ログの保存期間（日数）
}

# AmazonECSTaskExecutionRolePolicyの参照
data "aws_iam_policy" "ecs_task_execution_role_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECSタスク実行IAMロールのポリシードキュメントの定義
data "aws_iam_policy_document" "ecs_task_execution" {
  source_policy_documents = [data.aws_iam_policy.ecs_task_execution_role_policy.policy]

  // AmazonECSTaskExecutionRolePolicyを継承しつつ、SSMパラメーターストアとKMSのアクセス許可を追加
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}
