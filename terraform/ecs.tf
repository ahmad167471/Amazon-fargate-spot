############################
# ECS CLUSTER
############################

resource "aws_ecs_cluster" "ahmad_cluster" {
  name = "ahmad-fargate-cluster"
}

############################
# TASK DEFINITION (FARGATE)
############################

resource "aws_ecs_task_definition" "ahmad_task" {
  family                   = "ahmad-fargate-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = "arn:aws:iam::811738710312:role/ecs_fargate_taskRole"
  task_role_arn      = "arn:aws:iam::811738710312:role/ecs_fargate_taskRole"

  container_definitions = jsonencode([
    {
      name      = "ahmad-container"
      image     = var.image_url
      essential = true

      portMappings = [{
        containerPort = 1337
        protocol      = "tcp"
      }]

      environment = [
         {
            name  = "DATABASE_CLIENT"
            value = "postgres"
             },
  {
    name  = "DATABASE_HOST"
    value = aws_db_instance.ahmad_db.address
  },
  {
    name  = "DATABASE_PORT"
    value = "5432"
  },
  {
    name  = "DATABASE_NAME"
    value = "postgres"
  },
  {
    name  = "DATABASE_USERNAME"
    value = var.db_username
  },
  {
    name  = "DATABASE_PASSWORD"
    value = var.db_password
  },
  {
  name  = "DATABASE_SSL"
  value = "true"
},
  {
    name  = "APP_KEYS"
    value = "key1,key2,key3,key4"
  },
  {
    name  = "API_TOKEN_SALT"
    value = "randomsalt123"
  },
  {
    name  = "ADMIN_JWT_SECRET"
    value = "adminjwtsecret123"
  },
  {
    name  = "JWT_SECRET"
    value = "jwtsecret123"
  },
  {
    name  = "HOST"
    value = "0.0.0.0"
  },
  {
    name  = "PORT"
    value = "1337"
  },
  {
    name  = "NODE_ENV"
    value = "production"
  }
]
    }
  ])
}

############################
# ECS SERVICE (FARGATE)
############################
resource "aws_security_group" "ecs_sg" {
  name        = "ahmad-ecs-sg"
  description = "Managed by Terraform"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 1337
    to_port         = 1337
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
resource "aws_ecs_service" "ahmad_service" {
  name            = "ahmad-service"
  cluster         = aws_ecs_cluster.ahmad_cluster.id
  task_definition = aws_ecs_task_definition.ahmad_task.arn
  desired_count   = 1
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }
  load_balancer {
  target_group_arn = aws_lb_target_group.ecs_tg.arn
  container_name   = "ahmad-container"  
  container_port   = 1337
}

  network_configuration {
  subnets          = data.aws_subnets.default.ids
  security_groups  = [aws_security_group.ecs_sg.id]
  assign_public_ip = true
}
  depends_on = [
    aws_lb_listener.ecs_listener
  ]
}
