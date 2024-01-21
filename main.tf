module "base" {
  source = "github.com/tfext/terraform-aws-base"
}

module "tagging" {
  source       = "github.com/tfext/terraform-utilities-tagging"
  environments = false
}

locals {
  name              = "jenkins"
  image             = "jenkins/jenkins"
  port              = 8080
  load_balancer_map = { for lb in var.load_balancers : lb.name => lb }
}

resource "aws_cloudwatch_log_group" "service" {
  name              = var.log_group
  retention_in_days = 3
}

resource "random_password" "initial_password" {
  length  = 15
  special = true
}

# resource "null_resource" "echo_password" {
#   provisioner "local-exec" {
#     command = "echo 'Nexus admin password (change immediately): ${nonsensitive(random_password.initial_password.result)}'"
#   }
#   depends_on = [random_password.initial_password]
# }

data "aws_iam_policy_document" "role_policy" {
  statement {
    sid       = "efs"
    resources = [data.aws_efs_file_system.efs.arn]
    actions = [
      "efs:*"
    ]
  }
}

module "container_definition" {
  source          = "github.com/tfext/terraform-aws-ecs-container-definition"
  name            = local.name
  image           = local.image
  image_tag       = var.jenkins_version
  memory_required = var.memory
  cpu             = var.vcpu

  environment = {
  }

  ports = [{
    port         = local.port
    public_port  = 443
    health_check = { status_codes = "200-499" }
  }]

  shared_data = {
    efs_id          = data.aws_efs_file_system.efs.file_system_id
    access_point_id = aws_efs_access_point.service.id
    mount_path      = "/${local.name}-data"
  }

  aws_logging = {
    group = aws_cloudwatch_log_group.service.name
  }
}

module "service" {
  source         = "github.com/tfext/terraform-aws-ecs-service"
  name           = local.name
  cluster        = var.ecs_cluster
  containers     = [module.container_definition]
  role_policy    = data.aws_iam_policy_document.role_policy.json
  singleton      = true
  load_balancers = var.load_balancers
  wait_for_stable = false # TODO
}
